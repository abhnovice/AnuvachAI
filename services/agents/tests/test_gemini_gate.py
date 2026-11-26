from __future__ import annotations

import asyncio
import json
import logging
import os
import time

import httpx
import pytest
import uvicorn
from google.adk.a2a.utils.agent_to_a2a import to_a2a

from anuvach_agents.fake_adapters import SQLiteFakeAdapters
from anuvach_agents.triage_agent import build_triage_agent
from anuvach_agents.workbench import create_app, gemini_configured
from test_language_matrix import LANGUAGE_CASES, free_port


@pytest.mark.gemini
def test_real_gemini_text_gate(tmp_path, monkeypatch):
    assert gemini_configured(), "Gemini credential missing from services/agents/.env"
    monkeypatch.setenv("TRIAGE_PROVIDER", "gemini")
    port = free_port()
    peer_url = f"http://127.0.0.1:{port}"
    card_url = f"{peer_url}/.well-known/agent-card.json"
    monkeypatch.setenv("TRIAGE_AGENT_CARD_URL", card_url)
    adapter = SQLiteFakeAdapters(tmp_path / "gemini.sqlite")
    agent = build_triage_agent()

    async def run():
        peer = uvicorn.Server(uvicorn.Config(
            to_a2a(agent, host="127.0.0.1", port=port),
            host="127.0.0.1", port=port, log_config=None,
        ))
        task = asyncio.create_task(peer.serve())
        metrics = []
        try:
            async with asyncio.timeout(10):
                while not peer.started:
                    await asyncio.sleep(0.02)
            async with httpx.AsyncClient(timeout=5) as peer_client:
                card = (await peer_client.get(card_url)).raise_for_status().json()
                assert card["name"] == agent.name
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=create_app(adapter)), base_url="http://workbench",
            ) as client:
                async def post(path, **body):
                    async with asyncio.timeout(60):
                        return (await client.post(path, json=body)).raise_for_status().json()

                selected = os.getenv("STAGE3_GEMINI_CASE")
                cases = (
                    {case: LANGUAGE_CASES[case] for case in selected.split(",")}
                    if selected else LANGUAGE_CASES
                )
                for case, statement in cases.items():
                    if metrics:
                        await asyncio.sleep(4)
                    language = case.split("-")[0]
                    started = time.perf_counter()
                    response = await post("/api/drafts", language=language, text=statement)
                    draft = response["draft"]
                    report_id = draft["report_id"]
                    diagnostics = (await client.get("/api/diagnostics")).json()
                    events = [item for item in diagnostics["tool_calls"] if
                              item["result"].get("report_id") == report_id]
                    reporting = next(item for item in reversed(events) if item["tool"] == "reporting_text")
                    row = {
                        "language": case,
                        "reporting": reporting["result"],
                        "reporting_pass": reporting["ok"],
                        "question": response["agent_reply"],
                        "exact_fact": draft["facts"][0]["text"] == statement
                        and draft["transcript"][0]["original_text"] == statement,
                        "tool_calls": [item["result"] for item in events
                                       if item["tool"] == "update_draft_unknowns"],
                    }
                    metrics.append(row)
                    if not reporting["ok"]:
                        print(json.dumps(row, ensure_ascii=False), flush=True)
                        continue
                    if case == "en":
                        follow_up = "The call was yesterday at about 3 pm. I did not share a pairing code."
                        second = await post("/api/drafts", language=language, text=follow_up, report_id=report_id)
                        draft = second["draft"]
                        row["follow_up"] = second["agent_reply"]
                        row["exact_fact"] &= draft["facts"][-1]["text"] == follow_up
                        corrected = follow_up.replace("about", "approximately")
                        draft["facts"][-1]["text"] = corrected
                        edited = await client.patch(f"/api/drafts/{report_id}", json={
                            "facts": draft["facts"], "unknowns": draft["unknowns"],
                        })
                        draft = edited.raise_for_status().json()
                        assert draft["transcript"][-1]["original_text"] == follow_up
                        assert draft["transcript"][-1]["corrected_text"] == corrected
                        row["edit_pass"] = True
                        second_events = (await client.get("/api/diagnostics")).json()["tool_calls"]
                        follow_up_event = next(
                            item for item in reversed(second_events) if item["tool"] == "reporting_text"
                        )
                        row["follow_up_reporting"] = follow_up_event["result"]
                        row["follow_up_pass"] = follow_up_event["ok"] and bool(second["agent_reply"])
                    assert not any(ticket["report"]["report_id"] == report_id
                                   for ticket in (await client.get("/api/tickets")).json())
                    declined = await client.post(f"/api/drafts/{report_id}/confirm", json={
                        "confirmed": False, "idempotency_key": f"gemini-{case}-confirm",
                    })
                    assert declined.status_code == 400
                    ticket = await post(f"/api/drafts/{report_id}/confirm", confirmed=True,
                                        revision=draft["revision"], idempotency_key=f"gemini-{case}-confirm")
                    row["time_to_confirmed_ticket_ms"] = round((time.perf_counter() - started) * 1000)
                    ticket_path = f"/api/tickets/{ticket['ticket_id']}"
                    triage = await post(f"{ticket_path}/triage", retry=True)
                    row["triage"] = triage
                    if triage["status"] == "completed":
                        repeated = await post(f"{ticket_path}/triage", retry=True)
                        assert repeated["task_id"] == triage["task_id"]
                        assert len(adapter.proposals_for_report(report_id)) == 1
                        row["decision"] = await post(f"{ticket_path}/decision", decision="accept")
                    print(json.dumps(row, ensure_ascii=False), flush=True)
            assert all(row["reporting_pass"] and row["exact_fact"] and row["question"]
                       and row["tool_calls"] and row["triage"]["status"] == "completed"
                       and row["triage"]["task_id"] and row["decision"]["acknowledged"]
                       and (row["language"] != "en" or row["follow_up_pass"] and row["edit_pass"])
                       for row in metrics), "See per-case results above"
        finally:
            peer.should_exit = True
            await task

    previous_disable = logging.root.manager.disable
    logging.disable(logging.CRITICAL)
    try:
        asyncio.run(run())
    finally:
        logging.disable(previous_disable)
