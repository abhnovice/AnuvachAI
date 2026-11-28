from __future__ import annotations

from datetime import datetime
from enum import StrEnum
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class Language(StrEnum):
    ENGLISH = "en"
    HINDI = "hi"
    TAMIL = "ta"
    TELUGU = "te"
    BENGALI = "bn"
    KANNADA = "kn"
    MALAYALAM = "ml"
    URDU = "ur"
    PUNJABI = "pa"


class IncidentType(StrEnum):
    SUPPORT_CALL = "support_call"
    EMAIL_PHISHING = "email_phishing"
    MESSAGING_PHISHING = "messaging_phishing"
    VOICE_PHISHING = "voice_phishing"
    DEEPFAKE_IMPERSONATION = "deepfake_impersonation"
    QR_PHISHING = "qr_phishing"
    PAYMENT_FRAUD = "payment_fraud"
    MFA_FATIGUE = "mfa_fatigue"
    REMOTE_ACCESS_SCAM = "remote_access_scam"
    SUSPICIOUS_MESSAGE = "suspicious_message"
    MISTAKEN_REPORT = "mistaken_report"
    OTHER = "other"


class FactSource(StrEnum):
    EMPLOYEE_STATEMENT = "employee_statement"
    CONSENTED_DEVICE_OBSERVATION = "consented_device_observation"


class Severity(StrEnum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    CRITICAL = "critical"
    UNASSESSED = "unassessed"


class ReceivingTeam(StrEnum):
    SECURITY = "security"
    IT_SUPPORT = "it_support"
    DATA_PROTECTION = "data_protection"
    UNKNOWN = "unknown"


class TranscriptTurn(StrictModel):
    turn_id: str = Field(min_length=1)
    speaker: Literal["employee", "agent"]
    language: Language
    original_text: str
    corrected_text: str | None = None
    timestamp: datetime


class ReportFact(StrictModel):
    fact_id: str = Field(pattern=r"^F[0-9]{3,}$")
    source: FactSource
    text: str = Field(min_length=1, max_length=4000)
    observed_at: datetime | None = None
    consented: bool = False
    observation_type: str | None = None

    @model_validator(mode="after")
    def validate_provenance(self) -> ReportFact:
        if self.source == FactSource.CONSENTED_DEVICE_OBSERVATION:
            if not self.consented or self.observed_at is None or not self.observation_type:
                raise ValueError(
                    "device observations require explicit consent, time, and observation type"
                )
        elif self.consented or self.observed_at is not None or self.observation_type is not None:
            raise ValueError("employee statements cannot be represented as device observations")
        return self


class ReportDraft(StrictModel):
    report_id: str = Field(min_length=1)
    revision: int = Field(ge=1)
    preferred_language: Language
    incident_type: IncidentType
    transcript: list[TranscriptTurn]
    facts: list[ReportFact] = Field(min_length=1)
    unknowns: list[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_fact_ids(self) -> ReportDraft:
        ids = [fact.fact_id for fact in self.facts]
        if len(ids) != len(set(ids)):
            raise ValueError("fact IDs must be unique within a report revision")
        return self


class ConfirmedReport(ReportDraft):
    confirmation_id: str = Field(min_length=1)
    confirmed_by: str = Field(min_length=1)
    confirmed_at: datetime
    correlation_id: str = Field(min_length=1)
    idempotency_key: str = Field(min_length=8, max_length=128)


class TriageReason(StrictModel):
    text: str = Field(min_length=1, max_length=1000)
    fact_ids: list[str] = Field(min_length=1)


class EvidenceReference(StrictModel):
    fact_id: str
    explains: str = Field(min_length=1, max_length=500)


class TriageProposal(StrictModel):
    proposal_id: str = Field(min_length=1)
    report_id: str = Field(min_length=1)
    report_revision: int = Field(ge=1)
    incident_type: IncidentType
    proposed_severity: Severity
    proposed_team: ReceivingTeam
    reasons: list[TriageReason] = Field(min_length=1)
    evidence_references: list[EvidenceReference] = Field(min_length=1)
    unknowns: list[str] = Field(default_factory=list)
    recommended_next_questions: list[str] = Field(default_factory=list)
    human_review_required: Literal[True] = True


class PolicyPassage(StrictModel):
    passage_id: str = Field(min_length=1)
    source_id: str = Field(min_length=1)
    text: str = Field(min_length=1)
    citation: str = Field(min_length=1)


class PolicyRetrievalRequest(StrictModel):
    report_id: str = Field(min_length=1)
    fact_ids: list[str] = Field(min_length=1)
    language: Language


class PolicyRetrievalResult(StrictModel):
    passages: list[PolicyPassage]
    retrieved_at: datetime


class IdentityContext(StrictModel):
    subject_id: str = Field(min_length=1)
    authenticated: bool
    role: Literal["employee", "administrator"]


def confirm_draft(
    draft: ReportDraft,
    *,
    explicit_confirmation: bool,
    identity: IdentityContext,
    confirmation_id: str,
    confirmed_at: datetime,
    correlation_id: str,
    idempotency_key: str,
) -> ConfirmedReport:
    if not explicit_confirmation:
        raise ValueError("explicit employee confirmation is required")
    if not identity.authenticated or identity.role != "employee":
        raise PermissionError("an authenticated employee identity is required")
    if len(idempotency_key) < 8 or len(idempotency_key) > 128:
        raise ValueError("idempotency key must be 8-128 characters")
    return ConfirmedReport(
        **draft.model_dump(),
        confirmation_id=confirmation_id,
        confirmed_by=identity.subject_id,
        confirmed_at=confirmed_at,
        correlation_id=correlation_id,
        idempotency_key=idempotency_key,
    )


def validate_proposal_for_report(
    proposal: TriageProposal, report: ConfirmedReport
) -> TriageProposal:
    if proposal.report_id != report.report_id or proposal.report_revision != report.revision:
        raise ValueError("triage proposal does not match the confirmed report revision")
    known_fact_ids = {fact.fact_id for fact in report.facts}
    cited_ids = {fact_id for reason in proposal.reasons for fact_id in reason.fact_ids}
    cited_ids.update(reference.fact_id for reference in proposal.evidence_references)
    if not cited_ids or not cited_ids.issubset(known_fact_ids):
        raise ValueError("triage evidence must reference facts in the confirmed report")
    if proposal.proposed_severity == Severity.CRITICAL:
        raise ValueError("critical severity cannot be established by this report contract")
    if proposal.proposed_severity == Severity.HIGH:
        raise ValueError("high severity lacks a cited fact with independently verified impact")
    return proposal
