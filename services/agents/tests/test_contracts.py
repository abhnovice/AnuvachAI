from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from anuvach_agents.contracts import (
    ConfirmedReport,
    FactSource,
    IncidentType,
    IdentityContext,
    Language,
    ReportDraft,
    ReportFact,
    TranscriptTurn,
    confirm_draft,
)


def draft() -> ReportDraft:
    return ReportDraft(
        report_id="R-100",
        revision=1,
        preferred_language=Language.HINDI,
        incident_type=IncidentType.SUPPORT_CALL,
        transcript=[
            TranscriptTurn(
                turn_id="T-1",
                speaker="employee",
                language=Language.HINDI,
                original_text="एक व्यक्ति ने मुझसे pairing code मांगा।",
                timestamp=datetime(2026, 11, 26, tzinfo=UTC),
            )
        ],
        facts=[
            ReportFact(
                fact_id="F001",
                source=FactSource.EMPLOYEE_STATEMENT,
                text="The caller requested a pairing code.",
            )
        ],
    )


def test_draft_is_not_a_confirmed_report() -> None:
    with pytest.raises(ValidationError):
        ConfirmedReport.model_validate(draft().model_dump())


def test_confirmation_requires_explicit_action_and_employee_identity() -> None:
    identity = IdentityContext(
        subject_id="synthetic-employee-1", authenticated=True, role="employee"
    )
    values = {
        "identity": identity,
        "confirmation_id": "C-100",
        "confirmed_at": datetime(2026, 11, 26, tzinfo=UTC),
        "correlation_id": "CORR-100",
        "idempotency_key": "confirm-key-100",
    }
    with pytest.raises(ValueError, match="explicit employee confirmation"):
        confirm_draft(draft(), explicit_confirmation=False, **values)
    with pytest.raises(PermissionError):
        confirm_draft(
            draft(),
            explicit_confirmation=True,
            **{**values, "identity": identity.model_copy(update={"role": "administrator"})},
        )
    confirmed = confirm_draft(draft(), explicit_confirmation=True, **values)
    assert confirmed.confirmed_by == identity.subject_id
    assert confirmed.facts[0].fact_id == "F001"


def test_device_observation_requires_consent_and_timestamp() -> None:
    with pytest.raises(ValidationError):
        ReportFact(
            fact_id="F002",
            source=FactSource.CONSENTED_DEVICE_OBSERVATION,
            text="A secure screen lock is configured.",
        )