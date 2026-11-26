from datetime import UTC, datetime

import pytest

from anuvach_agents.contracts import (
    ConfirmedReport,
    EvidenceReference,
    FactSource,
    IncidentType,
    Language,
    ReceivingTeam,
    ReportFact,
    Severity,
    TranscriptTurn,
    TriageProposal,
    TriageReason,
    validate_proposal_for_report,
)


def test_severity_unsupported_by_report_facts_is_rejected() -> None:
    moment = datetime.now(UTC)
    report = ConfirmedReport(
        report_id="R-SAFETY-1",
        revision=1,
        preferred_language=Language.ENGLISH,
        incident_type=IncidentType.SUPPORT_CALL,
        transcript=[
            TranscriptTurn(
                turn_id="T-1",
                speaker="employee",
                language=Language.ENGLISH,
                original_text="A caller asked for a pairing code.",
                timestamp=moment,
            )
        ],
        facts=[
            ReportFact(
                fact_id="F001",
                source=FactSource.EMPLOYEE_STATEMENT,
                text="A caller asked for a pairing code.",
            )
        ],
        confirmation_id="C-1",
        confirmed_by="employee-1",
        confirmed_at=moment,
        correlation_id="CORR-1",
        idempotency_key="safety-key-1",
    )
    proposal = TriageProposal(
        proposal_id="P-1",
        report_id=report.report_id,
        report_revision=report.revision,
        incident_type=IncidentType.SUPPORT_CALL,
        proposed_severity=Severity.HIGH,
        proposed_team=ReceivingTeam.SECURITY,
        reasons=[TriageReason(text="The report proves compromise.", fact_ids=["F001"])],
        evidence_references=[EvidenceReference(fact_id="F001", explains="Caller request")],
        human_review_required=True,
    )
    with pytest.raises(ValueError, match="lacks a cited fact"):
        validate_proposal_for_report(proposal, report)

    critical = proposal.model_copy(update={"proposed_severity": Severity.CRITICAL})
    with pytest.raises(ValueError, match="cannot be established"):
        validate_proposal_for_report(critical, report)
    fabricated = proposal.model_copy(update={
        "proposed_severity": Severity.UNASSESSED,
        "evidence_references": [EvidenceReference(fact_id="F999", explains="Nonexistent")],
    })
    with pytest.raises(ValueError, match="facts in the confirmed report"):
        validate_proposal_for_report(fabricated, report)
