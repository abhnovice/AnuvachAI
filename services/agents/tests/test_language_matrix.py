from __future__ import annotations

import asyncio
import json
import socket

import uvicorn
from fastapi.testclient import TestClient
from google.adk.a2a.utils.agent_to_a2a import to_a2a

from anuvach_agents.a2a_client import send_confirmed_report
from anuvach_agents.contracts import ConfirmedReport
from anuvach_agents.fake_adapters import SQLiteFakeAdapters
from anuvach_agents.synthetic_agent import build_synthetic_triage_agent
from anuvach_agents.workbench import create_app


LANGUAGE_CASES = {
    "en": "I received a suspicious support call.",
    "hi": "मुझे एक संदिग्ध सहायता कॉल आया।",
    "ta": "எனக்கு சந்தேகமான ஆதரவு அழைப்பு வந்தது.",
    "te": "నాకు అనుమానాస్పద మద్దతు కాల్ వచ్చింది.",
    "bn": "আমি একটি সন্দেহজনক সহায়তা ফোন পেয়েছি।",
    "kn": "ನನಗೆ ಅನುಮಾನಾಸ್ಪದ ಬೆಂಬಲ ಕರೆ ಬಂದಿದೆ.",
    "ml": "എനിക്ക് സംശയാസ്പദമായ സഹായ കോൾ ലഭിച്ചു.",
    "ur": "مجھے ایک مشکوک معاونتی کال موصول ہوئی۔",
    "pa": "ਮੈਨੂੰ ਇੱਕ ਸ਼ੱਕੀ ਸਹਾਇਤਾ ਕਾਲ ਆਈ।",
    "ta-mixed": "IT support என்று சொன்னவர் pairing code கேட்டார்.",
}


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def test_native_script_drafts_round_trip_over_synthetic_a2a(tmp_path) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "languages.sqlite")
    client = TestClient(create_app(adapters))
    ticket_ids: list[str] = []
    for language, text in LANGUAGE_CASES.items():
        language_code = "ta" if language == "ta-mixed" else language
        draft = client.post(
            "/api/drafts",
            json={"text": text, "language": language_code, "incident_type": "support_call"},
        ).json()["draft"]
        assert draft["transcript"][0]["original_text"] == text
        assert draft["facts"][0]["text"] == text
        assert draft["facts"][0]["fact_id"] == "F001"
        response = client.post(
            f"/api/drafts/{draft['report_id']}/confirm",
            json={"confirmed": True, "idempotency_key": f"language-key-{language}"},
        )
        assert response.status_code == 200
        ticket_ids.append(response.json()["ticket_id"])

    reports = [
        ConfirmedReport.model_validate_json(json.dumps(item["report"], ensure_ascii=False))
        for item in client.get("/api/tickets").json()
        if item["ticket_id"] in ticket_ids
    ]
    assert len(reports) == len(LANGUAGE_CASES)

    async def run_remote_tasks() -> None:
        port = free_port()
        card_url = f"http://127.0.0.1:{port}/.well-known/agent-card.json"
        app = to_a2a(build_synthetic_triage_agent(), host="127.0.0.1", port=port)
        server = uvicorn.Server(
            uvicorn.Config(app, host="127.0.0.1", port=port, log_level="error")
        )
        server_task = asyncio.create_task(server.serve())
        try:
            for _ in range(200):
                if server.started:
                    break
                await asyncio.sleep(0.01)
            assert server.started
            for report in reports:
                result = await send_confirmed_report(report, agent_card_url=card_url)
                assert result.task_id
                assert result.proposal.report_id == report.report_id
                assert result.proposal.evidence_references[0].fact_id == report.facts[0].fact_id
        finally:
            server.should_exit = True
            await server_task

    asyncio.run(run_remote_tasks())