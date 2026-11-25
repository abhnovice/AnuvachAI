# Dashboard metrics and synthetic examples

The administrator overview follows the supplied incident-management reference while retaining Anuvach's mint/teal theme. It measures reporting and review workflow, not attack detection or security severity.

## Data and scope

Source: local SQLite reports plus append-only audit events. The interface labels the data as synthetic. The reporting selector supports 30, 90 or 180 UTC calendar days through the current instant, including today. Category filters apply to the overview and queue. Queue status filters do not change overview aggregates.

The cohort is reports received within the selected UTC window and incident category. The queue paginates that cohort in groups of ten, with status filtering applied. The API still returns arrays; pagination is a client presentation feature. Existing employee history reads remain unbounded unless a days filter is explicitly supplied.

Counts and charts use the API response rather than hard-coded browser fixtures. Failed requests display unavailable/error states; no chart silently substitutes sample values.

## Measurements

| View                            | Definition                                                                                                                                                                                                                                                          |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Reports received                | Number of reports received within the cohort window. Change compares with the preceding window of exactly the same elapsed duration. When the preceding count is zero, percentage change is unavailable.                                                            |
| Still open                      | Cohort reports whose current status is anything except closed, including awaiting_employee and escalated.                                                                                                                                                           |
| Currently closed / closed share | Currently closed cohort reports; share divides by all reports in that cohort. It is not an SLA success rate or proof that an incident was resolved.                                                                                                                 |
| Mean and median time to close   | Hours from receipt to the latest transition into closed for currently closed cohort reports with an auditable closure timestamp. Notes and assignment edits do not change closure time. Reopened reports are excluded until closed again. The sample size is shown. |
| First administrator action      | Receipt to the first recorded administrator mutation, including assignment, note, status or escalation decision. It is not employee response time or time of first viewing. Reports without an action are excluded from the average; sample size is shown.          |
| Unassigned                      | Cohort reports without a responsible team assignment. An assigned team with an empty reviewer is not counted as unassigned.                                                                                                                                         |
| Oldest open report              | Maximum age since receipt among currently open cohort reports.                                                                                                                                                                                                      |
| Incoming reports                | Cohort receipts in consecutive seven-day buckets starting at the reporting-window boundary; the last bucket can be shorter. Zero buckets remain visible.                                                                                                            |
| Incident mix                    | Counts and shares for employee-selected categories. Rounded shares may not add to exactly 100%. Legend buttons filter the category.                                                                                                                                 |
| Received vs closed              | New receipts and actual transitions into closed, grouped by calendar month inside the reporting window. Closures can concern reports received earlier. Partial boundary months are included. Repeated closed-to-closed writes are not new closures.                 |
| Closure gauge and duration bins | Gauge shows closed share. Bins count eligible latest closure durations: under 8h, 8–24h, 1–3 days and 3+ days. There is no invented time target.                                                                                                                    |
| Status matrix                   | Current cohort counts by incident type and workflow status. Clicking a cell selects its category and queue status.                                                                                                                                                  |
| Open & closed workload          | Historical states reconstructed from audit events at each plotted bucket end. Includes matching reports received before the window. Reopening moves a case back to open. It is a stock count, not that bucket's receipt/closure count.                              |
| Responsibility                  | Current team assignments across the cohort, with security and data protection kept separate.                                                                                                                                                                        |

All chart axes retain a zero baseline. Color is supplemented with labels, counts, tooltips, keyboard-focusable marks or controls, and expandable value tables. Time-series values use UTC; queue receipt/detail timestamps use the browser's local display conventions.

## Synthetic history

Run from the repository root:

```bash
npm run seed
```

This preserves the original two sample cases and adds 48 historical scenarios across roughly five months. Scenarios cover all four incident types, all five statuses, English/Hindi/mixed accounts, optional app/evidence notes, selected fictional device observations, team assignment, reviewer notes and explicit escalation decisions.

Fixture timestamps are authored synthetic history, not evidence of real employee activity. The seed's internal clock is not exposed as an API request parameter. The first run pins its fixture epoch in a seed-only metadata table. Stable idempotency keys prevent duplicates; subsequent runs skip existing fixtures and preserve administrator edits and audit history. No report is reset or deleted. Seed fixtures naturally age out of short reporting windows over time.

## API

`GET /api/v1/dashboard?days=90&incidentType=support_call` returns scope/provenance, headline metrics, weekly receipt/snapshot rows, monthly activity, category/status counts, turnaround bins and team counts. days defaults to 90; supported values are 30, 90 and 180. incidentType is optional and uses the existing report enum. Unsupported values/unknown parameters return 400.

`GET /api/v1/reports` additionally accepts optional `days=30|90|180` to select the same receipt cohort. Omitting it preserves the existing history contract. Analytics introduces no changes to report creation, confirmation, assignment or escalation payloads.

## Verification

API tests verify closure/reopening semantics, no-op closes, date/category filters, null denominators, aggregate reconciliation, query validation and idempotent fixtures preserving later edits. The dashboard workflow test still exercises status persistence and separate escalation confirmation. A real-API Flutter → React → Flutter test protects the shared reporting path.

Chromium checks covered all six rendered panels, comparison with the API's headline count, window/category/matrix filters, value-table disclosure, and a 390px layout without horizontal page overflow or JavaScript errors.
