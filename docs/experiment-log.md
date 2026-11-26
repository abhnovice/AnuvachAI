# Experiment log

## Environment and increments — 2026-11-25

Initial repository: IDE metadata only, no application files or commits. Node 26.13.0 and npm 12.2.2 available; Flutter/Dart/Java absent from PATH; Android SDK installed, no attached device.

Installed ignored workspace Flutter 3.38.5 (Dart 3.10.4) and Temurin JDK 17.0.21.1. Flutter archive SHA-256 matches the official release index: a264940cfc431c1778f34f7413fa6ab71443ad52c71f38c50b0284397a4039b0. Flutter's JDK setting now points at this local JDK.

1. API: implemented schema/version 1, validation, reports, assignment, notes, escalation, idempotency and transactional audit. Seed created two synthetic cases. Initial TypeScript test-helper type error corrected.
2. React: implemented queue/detail/workflow. TypeScript checks, API tests, React interaction test, API compilation and Vite build passed. npm installation reported zero vulnerabilities; npm 12 reported blocked optional esbuild postinstall, but builds/tests succeeded using installed platform packages.
3. Flutter: generated Android/iOS projects, reporting screens, persisted drafts and native device interface. Style issues corrected. Unit/widget tests passed (2 tests; live test skipped by default). Review cancellation sends nothing; edits invalidate confirmation; failed requests retain a frozen payload and key across restart.
4. Shared-API demonstration: `npm run test:live` passed. A real Flutter form/review/confirmation submitted via HTTP to an isolated SQLite-backed API; the real React component found its ticket and saved in_review; Flutter refreshed and rendered in_review. React ran in jsdom and Flutter in its host widget runner. This is not an emulator or browser visual test. Early test attempts failed because of scrolling and fake-clock settlement around real HTTP; corrected test frame handling and viewport configuration. Product timeouts remain enabled.
5. Android debug build: first build downloaded NDK 28.2.13676358, Build Tools 35, Android platform 36 and CMake 3.22.1 using existing accepted SDK licenses. Passed: generated build/app/outputs/flutter-apk/app-debug.apk (first build took approximately 12 minutes).
6. Headless API-37 emulator started successfully and appeared in adb. First native test install failed because the emulator was still booting. After sys.boot_completed returned 1, the same test passed: Kotlin returned an actual boolean secure-lock configuration through the Dart platform interface with source and UTC timestamp.

## Commands

| Command                                                                     | Result                                                                           |
| --------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `npm install`                                                               | Passed; root package-lock generated                                              |
| `npm run check`                                                             | Passed                                                                           |
| `npm test`                                                                  | Passed API and dashboard tests; opt-in live test skipped                         |
| `npm run build`                                                             | Passed API TypeScript compilation and Vite production build                      |
| `npm run seed`                                                              | Passed; two synthetic cases                                                      |
| `flutter pub get`                                                           | Passed; pubspec.lock generated                                                   |
| `flutter test`                                                              | Passed confirmation/retry tests                                                  |
| `npm run test:live`                                                         | Passed complete shared-API flow                                                  |
| `flutter doctor -v`                                                         | Reports missing Android command-line tools and Chrome; Linux cannot validate iOS |
| `flutter build apk --debug --project-dir=apps/mobile`                       | Failed: unsupported CLI option; corrected by running in apps/mobile              |
| `flutter build apk --debug`                                                 | Passed; debug APK generated                                                      |
| `flutter analyze`                                                           | Passed with no issues after final test style cleanup                             |
| `dart format --output=none --set-exit-if-changed lib test integration_test` | Passed                                                                           |
| `flutter test integration_test/device_review_test.dart -d emulator-5554`    | Passed on API 37 after boot; initial attempt failed with device still booting    |
| `npm run format:check`                                                      | Passed                                                                           |
| iOS build                                                                   | Pending macOS with Xcode                                                         |

## Simulation and outstanding validation

Only demo identities, seeded narratives and placeholder branding are simulated. HTTP transport, report persistence, administrator changes and audit events are implemented. Voice, policy retrieval, AI severity and automated triage are inactive, with explicit UI labels.

iOS compilation, signing, device settings and local-network prompts need macOS/Xcode. Human screen-reader/text-scaling tests and production access controls remain outside this synthetic iteration. No real employee information was used.

## Interface refresh — 2026-11-25

Reworked mobile and dashboard around the supplied Dhalam reference: mint/teal tokens, bundled Noto Sans, rounded cards, mobile navigation and a sidebar-based administrator desk. See [design-refresh.md](design-refresh.md) for sources and decisions.

Flutter analysis, unit tests and APK build passed. API/dashboard tests, TypeScript checking and Vite build passed. The real shared-API flow passed after fixing an existing test race: a refresh request must finish even when an administrator update was already visible from the initial load. Browser checks covered desktop/narrow detail layouts, sidebar filters, no page overflow and no JavaScript errors. One early browser check incorrectly assumed the local in-review queue was empty; it was corrected to validate the filter against the actual synthetic data. Android welcome/Home were visually checked using software rendering on the emulator. Application rendering defaults and native check behavior were not changed.

## Distribution size audit — 2026-11-25

Inspected the existing 185,128,524-byte debug APK. Built architecture-specific optimized release APKs at 16.18 / 18.59 / 20.02 MB. A 50.53 MB universal release failed the strict 50 MB budget; the documented distribution script now builds separate architecture APKs and enforces the budget. Kept all architectures, app features, demo connectivity and existing signing identity. Removed the rejected universal build artifact.

Compressed the complete web font to WOFF2 (2,049,096 → 889,484 bytes) and removed obsolete summary styles and an already-hidden placeholder. Desktop/detail/narrow screenshots had zero changed pixels. TypeScript checks, API/dashboard tests, production builds, live shared-API flow and browser chart interactions passed. The release APK installed and loaded API history on the emulator. See [size-optimization.md](size-optimization.md) for measurements, commands and limitations.

## Visual incident analytics — 2026-11-25

Added the requested six-panel overview: incoming trend, incident mix, received/closed activity, closure/turnaround, status matrix and historical open/closed workload. Added UTC reporting windows, category drill-downs, queue pagination and assignment visibility. Preserved the existing theme and externally updated base stylesheet; chart styles live in separate files.

Added a computed dashboard endpoint and 48 historical synthetic cases without resetting the original cases or administrator edits. API tests passed for closure/reopening/no-op semantics, empty denominators, scope reconciliation, input validation and idempotent fixture seeding. Existing dashboard mutation and escalation-confirmation tests passed. Chromium verified six rendered charts, API/KPI agreement, filters, accessible values and a narrow layout without page overflow or JavaScript errors. See dashboard-metrics.md for definitions and fixture limitations.

## Standalone Agents — 2026-11-26

Repository inspection confirmed Stages 1-2 are the Flutter employee report/review/confirmation flow, React administrator queue, and synthetic unauthenticated Fastify/SQLite API. No voice agent, Gemini integration, triage, or authenticated endpoint existed. The Stage 3 service is separate and has not connected to the existing API or changed either app.

Installed and exercised `google-adk 2.15.1`, `a2a-sdk 1.3.1`, `google-genai 2.34.0`, `pydantic 2.14.4`, and Python 3.15.2 in `services/agents/.venv`. The configured AI Studio model is `gemini-2.5-flash-native-audio-preview-12-2025`; triage defaults to `gemini-2.5-flash`. No usable key was configured, so neither Gemini model was invoked. The supplied key appeared in chat and must be rotated before local use.

Offline tests cover strict report contracts, consented observation provenance, explicit confirmation, idempotent confirmed-ticket creation and retry, separate proposal storage, unsupported severity rejection, A2A card retrieval, real ADK remote task exchange, malformed/unconfirmed input rejection, task IDs, peer outage/recovery, admin authorization, and ten native/mixed-script text cases. Offline A2A uses a deterministic synthetic ADK responder over HTTP; it is not model triage. Synthetic A2A latency is measured per task in diagnostics but is not representative of Gemini latency.

Live voice, model-generated fact extraction/read-back, language-specific speech transcription, interruption and reconnect behavior have not been measured. No voice quality parity is claimed. Tool/audit diagnostics cover local application events; there are no Gemini function tools in the offline responder. The existing port-3000 API is not contacted. Stage 4 policy retrieval is an unused typed interface only.

### Stage 3 Gate Status

| Gate | Result | Evidence / limitation |
| --- | --- | --- |
| 1. Repository contracts and fake adapters | Passed | Existing API/docs inspected; strict contracts, local SQLite adapters, and focused tests added. |
| 2. Reporting draft | Partial | Text drafts and editable facts work; no model-generated extraction was run. |
| 3. Gemini triage | Partial | Configurable ADK LlmAgent and output schema exist; no Gemini call was run. |
| 4. A2A boundary | Passed with synthetic peer | Real card retrieval and remote task exchange, malformed pre-model rejection, task ID, unavailable-peer recovery, same-key retry, and no duplicate proposal tested. |
| 5. Live voice | Not verified | ADK Live/WebSocket and microphone client are implemented; no key/audio-device test was possible. |
| 6. Nine languages | Text-only partial | Ten native/mixed-script text exchanges passed; speech transcription and language-specific model extraction remain unmeasured. |
| 7. Full standalone flow | Passed with synthetic providers | Browser flow created an acknowledged ticket, used remote synthetic A2A triage, displayed fact references, and recorded a simulated admin decision. |
| 8. Flutter/React integration | Deferred | Exact proposal is documented; neither existing app was modified. Do not integrate until Gates 2, 3, 5, and live-language checks are verified. |

The final automated Python suite passed 18 tests. Browser checks verified desktop and mobile layouts, the offline microphone-disabled state, A2A task/correlation diagnostics after restart, persisted evidence references, and a simulated decision acknowledgement. The only test warning is Starlette's deprecation warning for its `httpx`-based `TestClient`.

### Stage 3 real-model verification continuation

The service loaded `services/agents/.env` with `GOOGLE_API_KEY`. The original `gemini-2.5-flash` reporting probe returned `NOT_FOUND` and `gemini-3.8-flash` timed out or returned `UNAVAILABLE`. The successful text reporting and triage model was `gemini-3.5-flash-lite`. The real triage request now submits the strict contract as a Gemini JSON schema and validates the returned proposal against the confirmed ticket after the A2A call.

Commands from `services/agents`:

| Command | Result |
| --- | --- |
| `.venv/bin/python -m pytest` | 18 passed, 2 opt-in tests skipped. Synthetic card, outage, retry, confirmation and no duplicate proposal covered. |
| `node --check workbench/app.js` | Passed. |
| `STAGE3_GEMINI_CASE=en REPORTING_TEXT_MODEL=gemini-3.5-flash-lite TRIAGE_MODEL=gemini-3.5-flash-lite .venv/bin/python -m pytest --gemini -s tests/test_gemini_gate.py` | 1 passed. The stricter repeat also passed with both Gemini turns, an actual draft correction, confirmed ticket, A2A proposal and admin acknowledgement. |
| `REPORTING_TEXT_MODEL=gemini-3.5-flash-lite TRIAGE_MODEL=gemini-3.5-flash-lite .venv/bin/python -m pytest --gemini -s` | 18 passed, 1 skipped, 1 failed. Two reporting cases hit provider quota. |
| `STAGE3_GEMINI_CASE=bn,kn,en REPORTING_TEXT_MODEL=gemini-3.5-flash-lite TRIAGE_MODEL=gemini-3.5-flash-lite .venv/bin/python -m pytest --gemini -s tests/test_gemini_gate.py` | Bengali completed. Kannada triage remained pending for human review after a peer failure. English stored the edit and completed triage after a second-turn deadline error. |
| `STAGE3_GEMINI_CASE=kn,en REPORTING_TEXT_MODEL=gemini-3.5-flash-lite TRIAGE_MODEL=gemini-3.5-flash-lite .venv/bin/python -m pytest --gemini -s tests/test_gemini_gate.py` | 1 passed. Both languages completed and English obtained the correction and second-turn model output. |
| `REPORTING_LIVE_MODEL=gemini-2.5-flash-native-audio-preview-12-2025 .venv/bin/python -m pytest --gemini-voice -s tests/test_gemini_voice.py` | 1 failed. English passed the input-quality check. Eight languages failed it. |

In test report `R-15db813c-ada1-4517-ba62-669c22e69507`, Gemini called the missing-facts tool, asked when the suspicious support call occurred, and asked what the caller requested after the second statement. A draft edit changed “about” to “approximately” and preserved the employee's original statement. The application rejected declined confirmation, then acknowledged explicit confirmation of the edited revision at 13.745 s. A2A task `06e9d0a3-8ae3-4be7-ba2a-6028749ee135` finished at 4.279 s with an unassessed, evidence-linked proposal. A duplicate returned the same task and left one proposal. The simulated administrator accepted the proposal and received `DEC-301db465-8b5c-4e1c-98a5-144d599b189b`.

See the [language matrix](language-test-matrix.md) for exact-case fidelity, latency, token counts, pricing estimate and speech findings. The standalone Chromium microphone and speaker path still needs a real-device session with native speakers, including barge-in and forced reconnect. Before connecting production clients, add authenticated ownership and review, versioned persistence contracts with idempotent confirmation and decisions, a private A2A route with durable retries, and monitoring for provider failure. Keep policy-specific answers unavailable until Stage 4 RAG is implemented and evaluated. Flutter, React and the Stage 1–2 API were outside this continuation's changes.

### Local Flutter and React agent integration

The existing Fastify API stores the confirmed report, pending triage, validated proposal, and administrator review in the existing SQLite report and audit tables. Flutter uses the existing report and confirmation screens. React presents the A2A result as an AI proposal with editable review values. Both clients communicate with the application API.

The default ports were in use, so the isolated tests used Fastify at 13101, a React Vite site at 15173, the agent bridge at 18000, and the A2A peer at 18111. The A2A card identified `admin_triage_agent` and the task response identified **Gemini responder**. The reporting and triage models were both `gemini-3.5-flash-lite`.

- `npm test` passed four API and five React tests, with one legacy live React test skipped. `npm run check` and `npm run build` passed.
- From `services/agents`, `AGENTS_DB_PATH=:memory: .venv/bin/python -m pytest` passed 18 tests with two opt-in tests skipped.
- From `apps/mobile`, `../../.tooling/flutter/bin/flutter analyze --no-pub` passed. `../../.tooling/flutter/bin/flutter test --no-pub` passed nine tests with one legacy live test skipped.
- From `apps/mobile`, `../../.tooling/flutter/bin/flutter test --no-pub integration_test/agent_reporting_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:13101` passed. It checked the Gemini reply and transcript, edited the report, required confirmation, displayed the acknowledged ID, and replayed the same payload and key.
- With the loopback A2A peer unavailable, ticket `ANV-7a8f6b80-f3ea-4084-a888-d4abd2ac2fe3` was created and stayed pending. An exact replay returned the same ID. After the peer started, the API stored one Gemini proposal on attempt 3, task `dd3baf0d-f29e-4e95-b2eb-41714e9902b5`.

Flutter uses text for this integration. The previous standalone voice gate returned no final audio or input on Tamil and Kannada in its final run, and six other non-English languages returned transcripts with zero exact reference-word recall. See the [speech results](language-test-matrix.md).

The local React site was exercised in headless FireDragon using WebDriver BiDi. The administrator accepted the AI proposal and then amended the reviewed severity to `low` with team `it_support`. One original proposal remained. The existing ticket status stayed `submitted` and assignment stayed empty.

| Ticket ID | A2A task ID | Responder | Final admin decision |
| --- | --- | --- | --- |
| `ANV-71db724c-710a-4d96-8d82-d0a13f18bedd` | `8e4a71dd-9605-4e8a-99c1-830354f3f091` | Gemini responder | Amended to low / it_support |

Service commands used for the alternate-port run. The agent commands were run from `services/agents`. The API and Vite commands were run from the repository root with a disposable path for `DB_PATH`.

```bash
export A2A_PORT=18111 TRIAGE_PROVIDER=gemini
export TRIAGE_AGENT_CARD_URL=http://127.0.0.1:18111/.well-known/agent-card.json
export AGENTS_DB_PATH=:memory:
.venv/bin/python -m uvicorn anuvach_agents.serve:workbench_app --host 127.0.0.1 --port 18000
.venv/bin/python -m uvicorn anuvach_agents.serve:a2a_app --host 127.0.0.1 --port 18111
PORT=13101 ADMIN_ORIGIN=http://127.0.0.1:15173 AGENTS_BASE_URL=http://127.0.0.1:18000 node --import tsx services/api/src/server.ts
(cd apps/admin && LOCAL_API_URL=http://127.0.0.1:13101 ../../node_modules/.bin/vite --host 127.0.0.1 --port 15173 --strictPort)
curl --fail --silent http://127.0.0.1:18111/.well-known/agent-card.json
node /tmp/anuvach-stage3-browser.mjs
```

### Stage 3 closeout verification

Flutter now offers opt-in Android voice alongside editable text. The Fastify relay opens a temporary preview connection to the existing Gemini Live WebSocket. It retains bounded data only in memory and forwards finalized transcript segments for explicit selection. Preview sessions create no agent draft or ticket. The Android channel captures mono PCM16 at 16 kHz. Gemini output is played through an Android PCM stream using the declared sample rate. The mocked Flutter test verified start-on-demand, partial exclusion, duplicate segment suppression, queued playback clearing on interruption, and visible disconnect and restart. The live English Fastify PCM relay returned the correct input transcript and an assistant transcript with first audio at 5.599 s. Closing, rejecting use of the closed session, and reopening passed. A separate English pairing-code fixture returned audio and transcripts but failed a literal phrase assertion. The associated transcript was not preserved, so that case was not used as an accuracy pass.

The final nine-language assessment used `gemini-2.5-flash-native-audio-preview-12-2025` and finished with one failed quality test. English preserved the incident fact at 4.821 s. Eight languages require text fallback, with Tamil and Kannada timing out and the other six losing the core fact. See the [per-language transcripts, corrections, omissions, output, and latency](language-test-matrix.md#stage-3-closeout-speech-assessment). No usable Live token or cost metadata was returned.

| Check | Result |
| --- | --- |
| `npm test` | 5 API and 5 React tests passed, 1 opt-in React test skipped |
| `npm run check` and `npm run build` | Passed |
| `AGENTS_DB_PATH=:memory: .venv/bin/python -m pytest` from `services/agents` | 18 passed, 2 opt-in tests skipped |
| `AGENTS_DB_PATH=:memory: STAGE3_VOICE_LANGUAGES=en,ta .venv/bin/python -m pytest --gemini-voice -s tests/test_gemini_voice.py` | English passed the fixture, Tamil timed out |
| `AGENTS_DB_PATH=:memory: .venv/bin/python -m pytest --gemini-voice -s tests/test_gemini_voice.py` | Final matrix, 1 quality test failed |
| `flutter analyze --no-pub` and `flutter test --no-pub --reporter expanded` from `apps/mobile` | Analysis clean, 19 passed, 1 opt-in test skipped. Nine native-script text flows and Urdu direction passed in Flutter and nine persisted contracts passed in Fastify. |
| `flutter test --no-pub integration_test/agent_reporting_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:13120` | Passed, with actual Gemini text reporting, explicit confirmation and duplicate replay |
| Headless FireDragon on `http://127.0.0.1:15120/` using WebDriver BiDi | Accepted and amended an AI proposal, then saved the existing ticket status as In review |

The integrated synthetic trace used ticket `ANV-fed67f14-bdc0-48d5-bdc5-8f5566290e8d`, A2A task `d953d8fc-0096-43ee-be45-411883d0051b`, **Gemini responder** with `gemini-3.5-flash-lite`, and final admin proposal review `amended / low / it_support`. The employee API returned `in_review`. Duplicate confirmation returned the same ticket with one proposal. The API regression rechecked pending state, restart recovery, and duplicate protection. The previous actual loopback outage and recovery trace is retained above.

Run the isolated agents with `A2A_PORT=18120 WORKBENCH_PORT=18020 TRIAGE_AGENT_CARD_URL=http://127.0.0.1:18120/.well-known/agent-card.json TRIAGE_PROVIDER=gemini AGENTS_DB_PATH=:memory: .venv/bin/python -m anuvach_agents.serve` from `services/agents`. Start Fastify with `PORT=13120 AGENTS_BASE_URL=http://127.0.0.1:18020 node --import tsx services/api/src/server.ts` and a disposable `DB_PATH`. Launch Vite from `apps/admin` with `LOCAL_API_URL=http://127.0.0.1:13120 ../../node_modules/.bin/vite --host 127.0.0.1 --port 15120 --strictPort`.

Stage 4 RAG can begin locally using the nine-language text baseline. Deployment requires authentication, ownership and administrator authorization, TLS and rate limits, transcript and audit retention policies, and physical-device voice verification for any advertised voice support. See the [local voice contract and security notes](../services/agents/README.md#stage-3-voice-closeout).

On the emulator, `flutter test --no-pub integration_test/voice_channel_test.dart -d emulator-5554` passed PCM frame capture, audio writes, and playback clearing. Permission was granted to the emulator test app by preinstalling its debug APK with `adb -s emulator-5554 install -r -g build/app/outputs/flutter-apk/app-debug.apk`. The employee's status display passed with `flutter test --no-pub integration_test/reviewed_ticket_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:13120 --dart-define=STAGE3_REVIEWED_TICKET=ANV-fed67f14-bdc0-48d5-bdc5-8f5566290e8d`. No physical phone or human listening test was available. Interruption was verified at the Flutter client with mocked voice events. Native audio I/O, real Gemini speech transport, and end-to-end text each have separate verification.
