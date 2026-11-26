from datetime import UTC, datetime

import pytest

from anuvach_agents.contracts import (
    ConfirmedReport,
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
    confirm_draft,
)
from anuvach_agents.fake_adapters import IdempotencyConflict, SQLiteFakeAdapters


@pytest.fixture
def confirmed() -> ConfirmedReport:
    moment = datetime(2026, 11, 26, tzinfo=UTC)
    draft = ReportDraft(
        report_id="R-200",
        revision=1,
        preferred_language=Language.ENGLISH,
        incident_type=IncidentType.SUPPORT_CALL,
        transcript=[
            TranscriptTurn(
                turn_id="T-1",
                speaker="employee",
                language=Language.ENGLISH,
                original_text="The caller requested a pairing code.",
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
    )
    return confirm_draft(
        draft,
        explicit_confirmation=True,
        identity=IdentityContext(subject_id="employee-2", authenticated=True, role="employee"),
        confirmation_id="C-200",
        confirmed_at=moment,
        correlation_id="CORR-200",
        idempotency_key="report-key-200",
    )


@pytest.fixture
def proposal() -> TriageProposal:
    return TriageProposal(
        proposal_id="P-200",
        report_id="R-200",
        report_revision=1,
        incident_type=IncidentType.SUPPORT_CALL,
        proposed_severity=Severity.UNASSESSED,
        proposed_team=ReceivingTeam.SECURITY,
        reasons=[TriageReason(text="A caller requested a pairing code.", fact_ids=["F001"])],
        evidence_references=[EvidenceReference(fact_id="F001", explains="Reported request")],
        unknowns=["Caller identity is unknown."],
        recommended_next_questions=["Was any code shared?"],
        human_review_required=True,
    )


def test_ticket_confirmation_is_idempotent_and_conflicts_are_rejected(
    tmp_path, confirmed
) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "local.sqlite")
    first = adapters.create_confirmed_ticket(confirmed)
    assert adapters.create_confirmed_ticket(confirmed) == first
    assert len(adapters.list_confirmed_tickets()) == 1
    different_key = confirmed.model_copy(update={"idempotency_key": "report-key-201"})
    with pytest.raises(IdempotencyConflict):
        adapters.create_confirmed_ticket(different_key)


def test_proposal_requires_confirmed_ticket_and_does_not_duplicate(
    tmp_path, confirmed, proposal
) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "local.sqlite")
    with pytest.raises(ValueError, match="confirmed ticket"):
        adapters.persist_proposal(proposal, "triage-key-200")
    adapters.create_confirmed_ticket(confirmed)
    assert adapters.persist_proposal(proposal, "triage-key-200") == "P-200"
    assert adapters.persist_proposal(proposal, "triage-key-200") == "P-200"
    assert len(adapters.proposals_for_report("R-200")) == 1


def test_admin_action_requires_authorized_identity(tmp_path, confirmed) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "local.sqlite")
    ticket_id = adapters.create_confirmed_ticket(confirmed)
    with pytest.raises(PermissionError):
        adapters.record_admin_decision(
            ticket_id=ticket_id,
            actor_id="employee-2",
            authenticated=True,
            role="employee",
            decision="accept",
            details={},
        )