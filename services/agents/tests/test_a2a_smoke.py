from __future__ import annotations

import asyncio
import json
import socket
from datetime import UTC, datetime

import httpx
import pytest
import uvicorn
from google.adk.a2a.utils.agent_to_a2a import to_a2a
from google.adk.models.llm_request import LlmRequest
from google.genai import types
from anuvach_agents.a2a_client import send_confirmed_report
from anuvach_agents.contracts import (
    ConfirmedReport,
    EvidenceReference,
    FactSource,
    IncidentType,
    Language,
    ReceivingTeam,
    ReportFact,
    ReportDraft,
    Severity,
    TranscriptTurn,
    TriageProposal,
    TriageReason,
)
from anuvach_agents.triage_agent import parse_confirmed_report_text, validate_a2a_input
from anuvach_agents.synthetic_agent import build_synthetic_triage_agent


def confirmed_report() -> ConfirmedReport:
    moment = datetime(2026, 11, 26, tzinfo=UTC)
    return ConfirmedReport(
        report_id="R-A2A-1",
        revision=1,
        preferred_language=Language.ENGLISH,
        incident_type=IncidentType.SUPPORT_CALL,
        transcript=[
            TranscriptTurn(
                turn_id="T-A2A-1",
                speaker="employee",
                language=Language.ENGLISH,
                original_text="A caller requested a pairing code.",
                timestamp=moment,
            )
        ],
        facts=[
            ReportFact(
                fact_id="F001",
                source=FactSource.EMPLOYEE_STATEMENT,
                text="A caller requested a pairing code.",
            )
        ],
        confirmation_id="C-A2A-1",
        confirmed_by="synthetic-employee",
        confirmed_at=moment,
        correlation_id="CORR-A2A-1",
        idempotency_key="report-key-a2a-1",
    )


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def test_agent_card_and_remote_task_exchange_and_bad_input_rejection() -> None:
    async def run() -> None:
        port = free_port()
        card_url = f"http://127.0.0.1:{port}/.well-known/agent-card.json"
        app = to_a2a(
            build_synthetic_triage_agent(),
            host="127.0.0.1",
            port=port,
        )
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
            async with httpx.AsyncClient() as client:
                response = await client.get(card_url)
            assert response.status_code == 200
            card = response.json()
            assert card["name"] == "synthetic_admin_triage_agent"
            assert card.get("skills")
            input_modes = card.get("defaultInputModes", card.get("default_input_modes", []))
            output_modes = card.get("defaultOutputModes", card.get("default_output_modes", []))
            assert any("text" in mode for mode in input_modes)
            assert any("text" in mode for mode in output_modes)

            result = await send_confirmed_report(confirmed_report(), agent_card_url=card_url)
            assert result.proposal.report_id == "R-A2A-1"
            assert result.proposal.reasons[0].fact_ids == ["F001"]
            assert result.task_id
            assert result.latency_ms > 0

            unconfirmed = ReportDraft.model_validate(
                {
                    key: value
                    for key, value in confirmed_report().model_dump().items()
                    if key not in {"confirmation_id", "confirmed_by", "confirmed_at", "correlation_id", "idempotency_key"}
                }
            )
            with pytest.raises(TypeError, match="only a ConfirmedReport"):
                await send_confirmed_report(unconfirmed)

            with pytest.raises(Exception):
                parse_confirmed_report_text(json.dumps({"report_id": "unconfirmed"}))
            malformed = LlmRequest(
                contents=[
                    types.Content(
                        role="user",
                        parts=[types.Part.from_text(text='{"report_id":"unconfirmed"}')],
                    )
                ]
            )
            with pytest.raises(ValueError, match="expected a valid CONFIRMED report"):
                validate_a2a_input(object(), malformed)
        finally:
            server.should_exit = True
            await server_task

    asyncio.run(run())