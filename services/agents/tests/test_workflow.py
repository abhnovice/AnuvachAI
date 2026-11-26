import asyncio
from datetime import UTC, datetime

import pytest

from anuvach_agents.a2a_client import A2AResult
from anuvach_agents.contracts import (
    EvidenceReference,
    FactSource,
    IdentityContext,
    IncidentType,
    Language,
    ReceivingTeam,
    ReportDraft,
    ReportFact,
    Severity,
    TranscriptTurn,
    TriageProposal,
    TriageReason,
)
from anuvach_agents.fake_adapters import SQLiteFakeAdapters
from anuvach_agents.workflow import StandaloneWorkflow


def make_draft() -> ReportDraft:
    now = datetime.now(UTC)
    return ReportDraft(
        report_id="R-WORKFLOW-1",
        revision=1,
        preferred_language=Language.ENGLISH,
        incident_type=IncidentType.SUPPORT_CALL,
        transcript=[
            TranscriptTurn(
                turn_id="T-1",
                speaker="employee",
                language=Language.ENGLISH,
                original_text="A caller asked for a pairing code.",
                timestamp=now,
            )
        ],
        facts=[
            ReportFact(
                fact_id="F001",
                source=FactSource.EMPLOYEE_STATEMENT,
                text="A caller asked for a pairing code.",
            )
        ],
    )


def make_proposal() -> TriageProposal:
    return TriageProposal(
        proposal_id="P-WORKFLOW-1",
        report_id="R-WORKFLOW-1",
        report_revision=1,
        incident_type=IncidentType.SUPPORT_CALL,
        proposed_severity=Severity.UNASSESSED,
        proposed_team=ReceivingTeam.SECURITY,
        reasons=[TriageReason(text="A caller asked for a code.", fact_ids=["F001"])],
        evidence_references=[EvidenceReference(fact_id="F001", explains="Reported request")],
        human_review_required=True,
    )


@pytest.mark.parametrize("confirmed_action", [False])
def test_declined_confirmation_creates_no_ticket(tmp_path, confirmed_action) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "local.sqlite")
    workflow = StandaloneWorkflow(adapters)
    with pytest.raises(ValueError, match="explicit employee confirmation"):
        workflow.confirm_report(
            make_draft(),
            explicit_confirmation=confirmed_action,
            identity=IdentityContext(subject_id="employee", authenticated=True, role="employee"),
            idempotency_key="confirmation-key-1",
        )
    assert adapters.list_confirmed_tickets() == []


def test_peer_outage_keeps_ticket_and_retries_without_duplicate(tmp_path) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "local.sqlite")
    calls = 0

    async def peer(report):
        nonlocal calls
        calls += 1
        if calls == 1:
            raise ConnectionError("peer unavailable")
        return A2AResult(
            proposal=make_proposal(),
            task_id="TASK-RETRY-1",
            latency_ms=12.5,
            agent_card_url="http://127.0.0.1:8011/.well-known/agent-card.json",
        )

    workflow = StandaloneWorkflow(adapters, triage_call=peer)
    report, ticket_id = workflow.confirm_report(
        make_draft(),
        explicit_confirmation=True,
        identity=IdentityContext(subject_id="employee", authenticated=True, role="employee"),
        idempotency_key="confirmation-key-2",
    )

    async def run():
        first = await workflow.triage_confirmed(report)
        second, duplicate = await asyncio.gather(
            workflow.triage_confirmed(report), workflow.triage_confirmed(report)
        )
        return first, second, duplicate

    first, second, duplicate = asyncio.run(run())
    assert first["human_review_required"] is True
    assert calls == 2
    assert duplicate["cached"] is True
    assert duplicate["task_id"] == second["task_id"]
    assert first["status"] == "pending"
    assert first["ticket_intact"] is True
    assert first["idempotency_key"] == second["idempotency_key"]
    assert second["status"] == "completed"
    assert second["task_id"] == "TASK-RETRY-1"
    assert len(adapters.proposals_for_report(report.report_id)) == 1
    assert adapters.read_confirmed_ticket(ticket_id) == report
    assert [event["action"] for event in adapters.list_audit()].count(
        "triage_a2a_failed"
    ) == 1
    assert [event["action"] for event in adapters.list_audit()].count(
        "triage_a2a_succeeded"
    ) == 1