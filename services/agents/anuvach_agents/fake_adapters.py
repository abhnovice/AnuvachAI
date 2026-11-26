from __future__ import annotations

import json
import sqlite3
import uuid
from datetime import UTC, datetime
from pathlib import Path

from .contracts import (
    ConfirmedReport,
    ReportDraft,
    ReportFact,
    TriageProposal,
    validate_proposal_for_report,
)
from .ports import AuditEvent


class IdempotencyConflict(ValueError):
    pass


class SQLiteFakeAdapters:
    """Local synthetic storage; it never contacts the Stage 1-2 API."""

    def __init__(self, path: str | Path = "data/agents.sqlite") -> None:
        self.path = str(path)
        Path(self.path).parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(self.path, check_same_thread=False)
        self.db.row_factory = sqlite3.Row
        self.db.executescript(
            """
            PRAGMA journal_mode=WAL;
            CREATE TABLE IF NOT EXISTS drafts (
                report_id TEXT PRIMARY KEY,
                payload TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS tickets (
                ticket_id TEXT PRIMARY KEY,
                report_id TEXT NOT NULL UNIQUE,
                idempotency_key TEXT NOT NULL UNIQUE,
                payload TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS proposals (
                proposal_id TEXT PRIMARY KEY,
                report_id TEXT NOT NULL,
                report_revision INTEGER NOT NULL,
                idempotency_key TEXT NOT NULL UNIQUE,
                payload TEXT NOT NULL,
                UNIQUE(report_id, report_revision)
            );
            CREATE TABLE IF NOT EXISTS triage_state (
                report_id TEXT NOT NULL,
                report_revision INTEGER NOT NULL,
                status TEXT NOT NULL,
                idempotency_key TEXT NOT NULL,
                task_id TEXT,
                latency_ms REAL,
                error TEXT,
                updated_at TEXT NOT NULL,
                PRIMARY KEY(report_id, report_revision)
            );
            CREATE TABLE IF NOT EXISTS decisions (
                decision_id TEXT PRIMARY KEY,
                ticket_id TEXT NOT NULL,
                actor_id TEXT NOT NULL,
                decision TEXT NOT NULL,
                payload TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS audit (
                sequence INTEGER PRIMARY KEY AUTOINCREMENT,
                event_id TEXT NOT NULL UNIQUE,
                at TEXT NOT NULL,
                action TEXT NOT NULL,
                subject_id TEXT NOT NULL,
                correlation_id TEXT NOT NULL,
                data TEXT NOT NULL
            );
            """
        )
        self.db.commit()

    def close(self) -> None:
        self.db.close()

    def reset(self) -> None:
        self.db.executescript(
            "DELETE FROM drafts; DELETE FROM tickets; DELETE FROM proposals; "
            "DELETE FROM triage_state; DELETE FROM decisions; DELETE FROM audit;"
        )
        self.db.commit()

    def save_draft(self, draft: ReportDraft) -> None:
        self.db.execute(
            "INSERT INTO drafts VALUES (?, ?) ON CONFLICT(report_id) DO UPDATE SET payload=excluded.payload",
            (draft.report_id, draft.model_dump_json()),
        )
        self.db.commit()

    def read_draft(self, report_id: str) -> ReportDraft | None:
        row = self.db.execute(
            "SELECT payload FROM drafts WHERE report_id=?", (report_id,)
        ).fetchone()
        return ReportDraft.model_validate_json(row["payload"]) if row else None

    def create_confirmed_ticket(self, report: ConfirmedReport) -> str:
        payload = report.model_dump_json()
        with self.db:
            by_key = self.db.execute(
                "SELECT ticket_id, payload FROM tickets WHERE idempotency_key=?",
                (report.idempotency_key,),
            ).fetchone()
            if by_key:
                if by_key["payload"] != payload:
                    raise IdempotencyConflict("retry key belongs to a different report")
                return str(by_key["ticket_id"])
            by_report = self.db.execute(
                "SELECT ticket_id FROM tickets WHERE report_id=?", (report.report_id,)
            ).fetchone()
            if by_report:
                raise IdempotencyConflict("report already has a confirmed ticket")
            ticket_id = f"SYN-{uuid.uuid4()}"
            self.db.execute(
                "INSERT INTO tickets VALUES (?, ?, ?, ?)",
                (ticket_id, report.report_id, report.idempotency_key, payload),
            )
            return ticket_id

    def read_confirmed_ticket(self, ticket_id: str) -> ConfirmedReport | None:
        row = self.db.execute(
            "SELECT payload FROM tickets WHERE ticket_id=?", (ticket_id,)
        ).fetchone()
        return ConfirmedReport.model_validate_json(row["payload"]) if row else None

    def find_ticket_by_idempotency_key(
        self, idempotency_key: str
    ) -> tuple[str, ConfirmedReport] | None:
        row = self.db.execute(
            "SELECT ticket_id, payload FROM tickets WHERE idempotency_key=?",
            (idempotency_key,),
        ).fetchone()
        if row is None:
            return None
        return str(row["ticket_id"]), ConfirmedReport.model_validate_json(row["payload"])

    def list_confirmed_tickets(self) -> list[tuple[str, ConfirmedReport]]:
        rows = self.db.execute(
            "SELECT ticket_id, payload FROM tickets ORDER BY rowid DESC"
        ).fetchall()
        return [
            (str(row["ticket_id"]), ConfirmedReport.model_validate_json(row["payload"]))
            for row in rows
        ]

    def persist_proposal(self, proposal: TriageProposal, idempotency_key: str) -> str:
        report = self.read_confirmed_report(proposal.report_id)
        if report is None:
            raise ValueError("triage requires an existing confirmed ticket")
        validate_proposal_for_report(proposal, report)
        payload = proposal.model_dump_json()
        with self.db:
            by_key = self.db.execute(
                "SELECT proposal_id, payload FROM proposals WHERE idempotency_key=?",
                (idempotency_key,),
            ).fetchone()
            if by_key:
                if by_key["payload"] != payload:
                    raise IdempotencyConflict("triage retry key belongs to a different proposal")
                return str(by_key["proposal_id"])
            by_revision = self.db.execute(
                "SELECT proposal_id, payload FROM proposals WHERE report_id=? AND report_revision=?",
                (proposal.report_id, proposal.report_revision),
            ).fetchone()
            if by_revision:
                if by_revision["payload"] != payload:
                    raise IdempotencyConflict("a different triage proposal already exists")
                return str(by_revision["proposal_id"])
            self.db.execute(
                "INSERT INTO proposals VALUES (?, ?, ?, ?, ?)",
                (
                    proposal.proposal_id,
                    proposal.report_id,
                    proposal.report_revision,
                    idempotency_key,
                    payload,
                ),
            )
            return proposal.proposal_id

    def read_confirmed_report(self, report_id: str) -> ConfirmedReport | None:
        row = self.db.execute(
            "SELECT payload FROM tickets WHERE report_id=?", (report_id,)
        ).fetchone()
        return ConfirmedReport.model_validate_json(row["payload"]) if row else None

    def list_proposals(self) -> list[TriageProposal]:
        rows = self.db.execute("SELECT payload FROM proposals ORDER BY rowid DESC").fetchall()
        return [TriageProposal.model_validate_json(row["payload"]) for row in rows]

    def proposals_for_report(self, report_id: str) -> list[TriageProposal]:
        rows = self.db.execute(
            "SELECT payload FROM proposals WHERE report_id=? ORDER BY rowid DESC",
            (report_id,),
        ).fetchall()
        return [TriageProposal.model_validate_json(row["payload"]) for row in rows]

    def record(self, event: AuditEvent) -> None:
        self.db.execute(
            "INSERT INTO audit(event_id, at, action, subject_id, correlation_id, data) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (
                event.event_id,
                event.at.isoformat(),
                event.action,
                event.subject_id,
                event.correlation_id,
                json.dumps(event.data, ensure_ascii=False),
            ),
        )
        self.db.commit()

    def record_a2a_result(
        self,
        *,
        report: ConfirmedReport,
        succeeded: bool,
        task_id: str | None,
        error: str | None = None,
        responder: str | None = None,
    ) -> None:
        self.record(
            _AuditEvent(
                event_id=str(uuid.uuid4()),
                at=datetime.now(UTC),
                action="triage_a2a_succeeded" if succeeded else "triage_a2a_failed",
                subject_id=report.confirmed_by,
                correlation_id=report.correlation_id,
                data={
                    "report_id": report.report_id,
                    "report_revision": report.revision,
                    "task_id": task_id,
                    "error": error,
                    "responder": responder,
                },
            )
        )

    def set_triage_state(
        self,
        *,
        report: ConfirmedReport,
        status: str,
        idempotency_key: str,
        task_id: str | None,
        latency_ms: float | None,
        error: str | None,
    ) -> None:
        if status not in {"pending", "completed"}:
            raise ValueError("unsupported triage state")
        self.db.execute(
            "INSERT INTO triage_state VALUES (?, ?, ?, ?, ?, ?, ?, ?) "
            "ON CONFLICT(report_id, report_revision) DO UPDATE SET "
            "status=excluded.status, idempotency_key=excluded.idempotency_key, "
            "task_id=excluded.task_id, latency_ms=excluded.latency_ms, "
            "error=excluded.error, updated_at=excluded.updated_at",
            (
                report.report_id,
                report.revision,
                status,
                idempotency_key,
                task_id,
                latency_ms,
                error,
                datetime.now(UTC).isoformat(),
            ),
        )
        self.db.commit()

    def get_triage_state(self, report_id: str, revision: int) -> dict[str, object] | None:
        row = self.db.execute(
            "SELECT * FROM triage_state WHERE report_id=? AND report_revision=?",
            (report_id, revision),
        ).fetchone()
        return dict(row) if row else None

    def list_audit(self) -> list[dict[str, object]]:
        rows = self.db.execute("SELECT * FROM audit ORDER BY sequence").fetchall()
        return [
            {
                "sequence": row["sequence"],
                "event_id": row["event_id"],
                "at": row["at"],
                "action": row["action"],
                "subject_id": row["subject_id"],
                "correlation_id": row["correlation_id"],
                "data": json.loads(row["data"]),
            }
            for row in rows
        ]

    def record_admin_decision(
        self,
        *,
        ticket_id: str,
        actor_id: str,
        authenticated: bool,
        role: str,
        decision: str,
        details: dict[str, object],
    ) -> str:
        if not authenticated or role != "administrator":
            raise PermissionError("an authenticated administrator is required")
        if decision not in {"accept", "edit", "reject"}:
            raise ValueError("unsupported simulated decision")
        if self.read_confirmed_ticket(ticket_id) is None:
            raise ValueError("ticket not found")
        decision_id = f"DEC-{uuid.uuid4()}"
        self.db.execute(
            "INSERT INTO decisions VALUES (?, ?, ?, ?, ?)",
            (decision_id, ticket_id, actor_id, decision, json.dumps(details)),
        )
        self.db.commit()
        self.record(
            _AuditEvent(
                event_id=str(uuid.uuid4()),
                at=datetime.now(UTC),
                action="simulated_admin_decision",
                subject_id=actor_id,
                correlation_id=ticket_id,
                data={"decision_id": decision_id, "decision": decision},
            )
        )
        return decision_id

    def decision_count(self) -> int:
        return int(self.db.execute("SELECT COUNT(*) FROM decisions").fetchone()[0])


class LocalFakeDeviceObservationAdapter:
    def observe(self, *, consented: bool, subject_id: str) -> list[ReportFact]:
        if not consented:
            return []
        return []


class _AuditEvent:
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