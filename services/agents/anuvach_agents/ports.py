from __future__ import annotations

from datetime import datetime
from typing import Protocol

from .contracts import (
    ConfirmedReport,
    PolicyPassage,
    PolicyRetrievalRequest,
    ReportDraft,
    ReportFact,
    TriageProposal,
)


class DraftStore(Protocol):
    def save_draft(self, draft: ReportDraft) -> None: ...

    def read_draft(self, report_id: str) -> ReportDraft | None: ...


class TicketStore(Protocol):
    def create_confirmed_ticket(self, report: ConfirmedReport) -> str: ...


class TicketReader(Protocol):
    def read_confirmed_ticket(self, ticket_id: str) -> ConfirmedReport | None: ...

    def list_confirmed_tickets(self) -> list[tuple[str, ConfirmedReport]]: ...


class DeviceObservationAdapter(Protocol):
    def observe(self, *, consented: bool, subject_id: str) -> list[ReportFact]: ...


class AuditEvent(Protocol):
    event_id: str
    at: datetime
    action: str
    subject_id: str
    correlation_id: str
    data: dict[str, object]


class AuditTrail(Protocol):
    def record(self, event: AuditEvent) -> None: ...


class TriageProposalStore(Protocol):
    def persist_proposal(self, proposal: TriageProposal, idempotency_key: str) -> str: ...


class Stage12ApiAdapter(Protocol):
    """Future authenticated adapter; intentionally not connected in Stage 3."""

    def create_report(self, report: ConfirmedReport, idempotency_key: str) -> str: ...

    def read_report(self, report_id: str) -> dict[str, object] | None: ...


class PolicyRetrievalPort(Protocol):
    """Stage 4 interface only; no policy source or retrieval is configured."""

    async def retrieve(
        self, request: PolicyRetrievalRequest
    ) -> list[PolicyPassage]: ...