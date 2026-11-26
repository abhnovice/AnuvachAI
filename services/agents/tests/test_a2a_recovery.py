from __future__ import annotations

import asyncio
import socket
from datetime import UTC, datetime

import uvicorn
from google.adk.a2a.utils.agent_to_a2a import to_a2a

from anuvach_agents.contracts import (
    ConfirmedReport,
    EvidenceReference,
    FactSource,
    IdentityContext,
    IncidentType,
    Language,
    ReportFact,
    TranscriptTurn,
    TriageProposal,
    TriageReason,
    Severity,
    ReceivingTeam,
)
from anuvach_agents.fake_adapters import SQLiteFakeAdapters
from anuvach_agents.synthetic_agent import build_synthetic_triage_agent
from anuvach_agents.workflow import StandaloneWorkflow


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def report() -> ConfirmedReport:
    moment = datetime.now(UTC)
    return ConfirmedReport(
        report_id="R-RECOVERY-1",
        revision=1,
        preferred_language=Language.ENGLISH,
        incident_type=IncidentType.SUPPORT_CALL,
        transcript=[
            TranscriptTurn(
                turn_id="T-RECOVERY-1",
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
        confirmation_id="C-RECOVERY-1",
        confirmed_by="synthetic-employee",
        confirmed_at=moment,
        correlation_id="CORR-RECOVERY-1",
        idempotency_key="recovery-report-key",
    )


def test_real_a2a_peer_outage_keeps_ticket_and_recovers(tmp_path, monkeypatch) -> None:
    port = free_port()
    card_url = f"http://127.0.0.1:{port}/.well-known/agent-card.json"
    monkeypatch.setenv("TRIAGE_AGENT_CARD_URL", card_url)
    adapters = SQLiteFakeAdapters(tmp_path / "recovery.sqlite")
    workflow = StandaloneWorkflow(adapters)
    employee = IdentityContext(
        subject_id="synthetic-employee", authenticated=True, role="employee"
    )
    ticket_id = adapters.create_confirmed_ticket(report())
    confirmed = adapters.read_confirmed_ticket(ticket_id)
    assert confirmed is not None

    async def run() -> None:
        first = await workflow.triage_confirmed(confirmed)
        assert first["status"] == "pending"
        assert first["ticket_intact"] is True

        server_app = to_a2a(
            build_synthetic_triage_agent(), host="127.0.0.1", port=port
        )
        server = uvicorn.Server(
            uvicorn.Config(server_app, host="127.0.0.1", port=port, log_level="error")
        )
        task = asyncio.create_task(server.serve())
        try:
            for _ in range(200):
                if server.started:
                    break
                await asyncio.sleep(0.01)
            assert server.started
            second = await workflow.triage_confirmed(confirmed)
            assert second["status"] == "completed"
            assert second["task_id"]
            assert first["idempotency_key"] == second["idempotency_key"]
        finally:
            server.should_exit = True
            await task

    asyncio.run(run())
    assert adapters.read_confirmed_ticket(ticket_id) == confirmed
    assert len(adapters.proposals_for_report(confirmed.report_id)) == 1
    actions = [item["action"] for item in adapters.list_audit()]
    assert actions.count("triage_a2a_failed") == 1
    assert actions.count("triage_a2a_succeeded") == 1