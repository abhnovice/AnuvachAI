from __future__ import annotations

import asyncio
import hashlib
import os
import time
import uuid
from datetime import UTC, datetime
from typing import Awaitable, Callable

from .a2a_client import A2AResult, InvalidTriageOutput, send_confirmed_report
from .contracts import ConfirmedReport, IdentityContext, ReportDraft, TriageProposal, confirm_draft, validate_proposal_for_report
from .fake_adapters import SQLiteFakeAdapters


TriageCall = Callable[[ConfirmedReport], Awaitable[A2AResult]]


class StandaloneWorkflow:
    def __init__(
        self,
        adapters: SQLiteFakeAdapters,
        triage_call: TriageCall = send_confirmed_report,
    ) -> None:
        self.adapters = adapters
        self.triage_call = triage_call
        self._triage_locks = [asyncio.Lock() for _ in range(32)]

    def save_draft(self, draft: ReportDraft) -> None:
        self.adapters.save_draft(draft)

    def confirm_report(
        self,
        draft: ReportDraft,
        *,
        explicit_confirmation: bool,
        identity: IdentityContext,
        idempotency_key: str,
    ) -> tuple[ConfirmedReport, str]:
        existing = self.adapters.find_ticket_by_idempotency_key(idempotency_key)
        confirmation_id = existing[1].confirmation_id if existing else f"CONF-{uuid.uuid4()}"
        confirmed_at = existing[1].confirmed_at if existing else datetime.now(UTC)
        correlation_id = existing[1].correlation_id if existing else f"CORR-{uuid.uuid4()}"
        confirmed = confirm_draft(
            draft,
            explicit_confirmation=explicit_confirmation,
            identity=identity,
            confirmation_id=confirmation_id,
            confirmed_at=confirmed_at,
            correlation_id=correlation_id,
            idempotency_key=idempotency_key,
        )
        ticket_id = self.adapters.create_confirmed_ticket(confirmed)
        self.adapters.record(
            _event(
                action="confirmed_synthetic_ticket_created",
                subject_id=identity.subject_id,
                correlation_id=confirmed.correlation_id,
                data={"report_id": confirmed.report_id, "ticket_id": ticket_id},
            )
        )
        return confirmed, ticket_id

    async def triage_confirmed(self, report: ConfirmedReport) -> dict[str, object]:
        lock = self._triage_locks[hash(report.report_id) % len(self._triage_locks)]
        async with lock:
            return await self._triage_confirmed(report)

    async def _triage_confirmed(self, report: ConfirmedReport) -> dict[str, object]:
        idempotency_key = hashlib.sha256(
            f"{report.report_id}:{report.revision}:triage".encode()
        ).hexdigest()
        existing = self.adapters.proposals_for_report(report.report_id)
        cached = next((item for item in existing if item.report_revision == report.revision), None)
        if cached:
            state = self.adapters.get_triage_state(report.report_id, report.revision)
            return {
                "status": "completed",
                "human_review_required": True,
                "proposal": cached.model_dump(mode="json"),
                "cached": True,
                "responder": "synthetic responder" if cached.proposal_id.startswith("SYN-P-") else None,
                "task_id": state.get("task_id") if state else None,
                "latency_ms": state.get("latency_ms") if state else None,
                "idempotency_key": idempotency_key,
            }
        started = datetime.now(UTC)
        timer = time.perf_counter()
        configured_responder = (
            "Gemini responder" if os.getenv("TRIAGE_PROVIDER", "synthetic").lower() == "gemini"
            else "synthetic responder"
        )
        task_id: str | None = None
        latency_ms: float | None = None
        try:
            result = await self.triage_call(report)
            proposal: TriageProposal = result.proposal
            task_id = result.task_id
            latency_ms = result.latency_ms
            try:
                validate_proposal_for_report(proposal, report)
            except ValueError as error:
                raise InvalidTriageOutput(str(error)) from error
            proposal_id = self.adapters.persist_proposal(proposal, idempotency_key)
            self.adapters.set_triage_state(
                report=report,
                status="completed",
                idempotency_key=idempotency_key,
                task_id=task_id,
                latency_ms=latency_ms,
                error=None,
            )
            self.adapters.record_a2a_result(
                report=report, succeeded=True, task_id=task_id,
                responder=result.responder or configured_responder,
            )
            return {
                "status": "completed",
                "human_review_required": True,
                "proposal_id": proposal_id,
                "responder": result.responder or configured_responder,
                "proposal": proposal.model_dump(mode="json"),
                "task_id": task_id,
                "latency_ms": latency_ms,
                "idempotency_key": idempotency_key,
            }
        except Exception as error:
            rejected = isinstance(error, InvalidTriageOutput)
            message = str(error) if rejected else f"A2A triage failed ({type(error).__name__})"
            latency_ms = (time.perf_counter() - timer) * 1000
            self.adapters.set_triage_state(
                report=report,
                status="pending",
                idempotency_key=idempotency_key,
                task_id=task_id,
                latency_ms=latency_ms,
                error=message,
            )
            self.adapters.record_a2a_result(
                report=report,
                succeeded=False,
                task_id=task_id,
                error=message,
                responder=configured_responder,
            )
            return {
                "status": "pending",
                "human_review_required": True,
                "responder": configured_responder,
                "failure_kind": "invalid_analysis" if rejected else "a2a_failure",
                "ticket_intact": self.adapters.read_confirmed_report(report.report_id)
                is not None,
                "task_id": task_id,
                "latency_ms": latency_ms,
                "idempotency_key": idempotency_key,
                "error": message,
                "failed_at": started.isoformat(),
            }

    def admin_decision(
        self,
        *,
        ticket_id: str,
        identity: IdentityContext,
        decision: str,
        details: dict[str, object],
    ) -> str:
        return self.adapters.record_admin_decision(
            ticket_id=ticket_id,
            actor_id=identity.subject_id,
            authenticated=identity.authenticated,
            role=identity.role,
            decision=decision,
            details=details,
        )


def _event(
    *, action: str, subject_id: str, correlation_id: str, data: dict[str, object]
) -> _WorkflowAuditEvent:
    return _WorkflowAuditEvent(
        event_id=str(uuid.uuid4()),
        at=datetime.now(UTC),
        action=action,
        subject_id=subject_id,
        correlation_id=correlation_id,
        data=data,
    )


class _WorkflowAuditEvent:
    def __init__(
        self,
        *,
        event_id: str,
        at: datetime,
        action: str,
        subject_id: str,
        correlation_id: str,
        data: dict[str, object],
    ) -> None:
        self.event_id = event_id
        self.at = at
        self.action = action
        self.subject_id = subject_id
        self.correlation_id = correlation_id
        self.data = data