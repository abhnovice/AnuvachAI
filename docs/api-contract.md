# API v1

Base: `http://127.0.0.1:3000/api/v1`. JSON bodies; errors use `{ "error": "message", "details": [...] }` with details for validation errors. Unknown body/query fields are rejected. Dates are UTC ISO 8601; server timestamps describe receipt/update, not the incident time.

## Creation

`POST /reports`, header `Idempotency-Key: CLIENT_UUID` (8–128 characters):

```json
{
  "employeeId": "demo-employee",
  "description": "Synthetic IT caller asked me to install an app and share a code.",
  "language": "english",
  "incidentType": "support_call",
  "appName": "",
  "evidenceNotes": "",
  "observations": [],
  "confirmed": true
}
```

Description: trimmed 10–5000 characters. Languages: `english | hindi | mixed`. Incident types: `support_call | suspicious_message | mistaken_report | other`. Optional appName max 200; evidenceNotes max 5000; both default to empty. Observations default to empty, max 10. Confirmation must be true.

An observation has `check: secure_screen_lock`, `platform: android`, boolean `value`, ISO `checkedAt`, and `source: client_public_api`. Value means configured/not configured, not security severity. Observation results are client-reported.

Returns 201 with report on first creation; same normalized payload/key returns the existing report with 200. A different payload with the same key returns 409. The client preserves the original key/payload on failure.

Report: `id` (ANV-prefixed UUID), `facts`, `createdAt`, `updatedAt`, `status`, `assignment` (null or team/reviewer), `version` (starts at 1). Status starts at `submitted`.

## Reads

- `GET /reports`: report array, newest first. Optional `employeeId=demo-employee`, `status`, `incidentType` exact filters.
- `GET /reports/:id`: employee report view.
- `GET /reports/:id?view=admin`: adds `audit`, `policyCitations: null`, `aiSeverity: null`.
- `GET /health` lives outside the v1 prefix and identifies the synthetic unauthenticated mode.

Admin notes are represented as note events in audit. Employee views exclude them. No pagination in this small local demo.

## Administrator mutations

Every body includes integer `expectedVersion` matching the report version. Successful changes increment version and return refreshed admin detail.

| Endpoint                        | Additional body                        |
| ------------------------------- | -------------------------------------- |
| `PATCH /reports/:id/status`     | `status: submitted                     | in_review                                                | awaiting_employee | closed` |
| `PATCH /reports/:id/assignment` | `team: security                        | data_protection`, optional `reviewer` max 100 characters |
| `POST /reports/:id/notes`       | `text`, trimmed 1–5000 characters      |
| `POST /reports/:id/escalations` | `confirmed: true`, `decision: escalate | do_not_escalate`, `reason` trimmed 3–5000 characters     |

Escalate sets status to `escalated`; do_not_escalate records the decision without changing status. Escalated tickets can subsequently be moved to any ordinary status by a reviewer. No automatic severity or risk ranking.

Audit events have increasing `sequence`, report association in storage, fixed synthetic `actor`, `action`, UTC `at`, and event `data`. Creation and each successful admin mutation add exactly one event atomically. Rejected and stale requests add none; idempotent creation retries add none.

Errors: 400 invalid input/confirmation; 404 missing ticket; 409 conflicting key or stale version; 500 storage/internal failure. Clients retain drafts on failure and refresh before resolving stale admin edits.

## Stage 3 consumers

Voice will populate the creation draft fields; it must pass through Flutter review before `POST /reports`. It can read employee history/detail through the existing GET endpoints using a future authenticated ownership context. Administrator workflow endpoints remain separate from voice tools. Do not expose unguarded escalation/status mutation tools to an employee voice agent.
