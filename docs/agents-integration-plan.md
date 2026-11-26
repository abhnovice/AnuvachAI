# Proposed Flutter and React Integration

This document describes the deferred production integration. The local synthetic-data integration uses the existing v1 API and SQLite report store. Gemini text and A2A are available for local testing. The multilingual voice gate failed, and Flutter uses text in the local flow. See the [local setup](../services/agents/README.md#local-flutter-and-react-integration).

## Existing Boundary

The current Stage 1-2 API accepts `POST /api/v1/reports` with `confirmed: true` and an `Idempotency-Key`, but its language contract is only `english | hindi | mixed`, report facts are comparatively flat, and the API has no authenticated identity/authorization. Flutter review and confirmation exist; React admin mutations exist. The local API is documented as unauthenticated synthetic demo mode. It is not a suitable direct target for real employee audio or model credentials.

## Flutter Employee App

1. Add a conversation repository that calls authenticated application endpoints only. Do not embed `GOOGLE_API_KEY` and do not call the A2A endpoint from Flutter.
2. Proposed API: `POST /api/v2/reporting/sessions` with preferred language; authenticated `POST /api/v2/reporting/sessions/{sessionId}/turns` for text or proxied live audio; `PATCH /api/v2/reporting/drafts/{reportId}` for edits; and `POST /api/v2/reports/{reportId}/confirm` with an idempotency key.
3. Keep the existing review/confirmation screen as the only ticket-creation action. Editing invalidates prior confirmation; the client persists the exact idempotency key and payload for retries.
4. Extend Flutter data types for nine language codes, original/corrected transcript turns, fact IDs, provenance, report revision, and unknowns. Keep fixed UI translations in ARB resources; only conversation content comes from the agent.
5. Show a ticket success state only after the authenticated API acknowledges the actual ticket ID. Keep voice/model failures as draft state; never claim an A2A task created a ticket.

## React Administrator Dashboard

1. Extend the authenticated API, not the browser, to call the private A2A triage peer after ticket confirmation. Never expose port `8011` to React.
2. Proposed API: `GET /api/v2/admin/reports/{reportId}/triage` returns the separately stored proposal and report fact references; `POST /api/v2/admin/reports/{reportId}/triage-decisions` accepts an authorized explicit `accept | edit | reject` decision, expected report version, and decision idempotency key.
3. Display proposal type/severity/team, each reason with fact IDs, unknowns, next questions, human-review requirement, and policy-grounding state. Do not render policy citations until Stage 4 retrieval has been implemented and validated.
4. Keep assignment/escalation/status mutations on existing authorized admin API paths. A recommendation must never trigger them automatically.
5. Show success only after the API returns a decision ID. Keep the A2A task ID and errors in server diagnostics/audit, not as an employee-client control surface.

## Server and Migration Work Before Integration

- Add authenticated employee ownership and administrator authorization to the application API, with TLS, rate limits, bounded reads, and durable, protected audit retention.
- Version the API contract for nine language codes, transcripts, fact provenance, consented observations, confirmed report revisions, triage proposal storage, and admin decisions. Preserve compatibility for existing Stage 1-2 clients during rollout.
- Add integration tests for identity/authorization, confirmation and idempotent retries, queue/detail visibility, concurrent edits, A2A outage recovery, and decision audit.
- Keep Gemini credentials server-side. The API service owns session routing and A2A calls; the A2A endpoint remains private to that service.

No Stage 4 AlloyDB, RAG, or policy corpus work is included in this proposal.