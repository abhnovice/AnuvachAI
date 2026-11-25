# Architecture

Flutter uses an API repository (`Api`), a persisted draft state object (`Draft`), and Material screens. SharedPreferences saves drafts and reviewed retry payloads locally. Review is side-effect free. Editing invalidates confirmation. Submission requires explicit confirmation and durably records the retry payload before attempting HTTP. Successful acknowledgement clears the draft. Ambiguous failures retain the same key and payload, preventing duplicate tickets when retried.

React uses typed fetch requests, queue filters and a report-detail panel. Status, team/reviewer assignment, notes and escalation decisions persist through the API. Escalation uses a separate confirmation dialog and endpoint. Each mutation carries the displayed report version; stale changes return 409 and require refresh.

Fastify validates input using Zod. SQLite stores immutable submitted facts within a versioned report record; administrator actions change report workflow fields and append audit events in one transaction. Schema version 1 is created at startup. Database triggers reject audit updates/deletes through SQL. This is local application-level append-only storage, not tamper-proof storage against a database owner.

## Boundaries

Employee responses omit administrator notes/audit. Administrator detail explicitly requests its view. This is response shaping, **not authorization**: anyone who can reach this demo API can ask for the admin view or change tickets. Demo identities and client confirmation flags are not trustworthy identity evidence. Device observations identify their client/API source; the server does not attest hardware or verify native execution.

Data protection and security are distinct role values for assignment; reviewer is a synthetic display string. No sign-in, role switching, or privilege enforcement is implied.

Before real employee data: enforce authenticated server identity, employee ownership on every read, server-issued administrator roles and separate data-protection permissions, note/audit access restrictions, reviewer/team membership validation, TLS, encrypted storage/backups, secrets management, retention/deletion policy, bounded pagination, rate limits and audit export/protection. Define which employee-visible status changes require notification and which facts each role needs. Do not trust an employeeId query parameter as access control.

## Stage 3 seam

A future conversation adapter should produce the existing structured draft fields through a typed draft interface, without calling submission automatically. Employee review and confirmation remain mandatory. Voice capture/consent, transcript retention, retrieval citations, model outputs and triage need separately versioned contracts and tests. No inactive feature requests microphone access.
