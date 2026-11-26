# Anuvach.AI Standalone Agents

An isolated Stage 3 Python prototype. It does not call `services/api`, Flutter, or React. The local browser workbench and A2A peer use synthetic identities/data by default. It is not production-ready.

## Setup

Use Python 3.11 or newer and run from the repository root:

```bash
cd services/agents
python3 -m venv .venv
.venv/bin/python -m pip install -e '.[test]'
cp -n .env.example .env
```

Enter your Gemini API key locally as `GOOGLE_API_KEY=...` in `services/agents/.env`, which Git ignores. The startup module loads this exact file before initializing the agents. Process environment values take precedence over the file. Google Gen AI also accepts `GEMINI_API_KEY`, with `GOOGLE_API_KEY` taking precedence. Keep the key in the service environment.

## Start and Test

One command starts both standalone services:

```bash
cd services/agents
.venv/bin/python -m anuvach_agents.serve
```

Open the developer workbench at <http://127.0.0.1:8000>. The A2A triage endpoint listens at <http://127.0.0.1:8011>; its card is at <http://127.0.0.1:8011/.well-known/agent-card.json>. Both bind to loopback by default. Port `3000` belongs to the existing Stage 1-2 API and is not used.

Run offline contract, failure-path, and A2A tests in another terminal:

```bash
cd services/agents
.venv/bin/python -m pytest
```

Stop both services with Ctrl+C. Local fake records are in ignored `services/agents/data/agents.sqlite`; use the workbench Reset control to clear them.

## Providers

The default `TRIAGE_PROVIDER=synthetic` runs the deterministic triage fixture over A2A. Scenario replay is deterministic even when a key is configured. Ordinary text entry uses the reporting Gemini agent when credentials are available and still saves an editable draft if Gemini is unavailable.

To use real Gemini triage, set `TRIAGE_PROVIDER=gemini`. Reporting uses `gemini-3.8-flash` for text and `gemini-3.8-live` for live voice; `TRIAGE_MODEL` defaults to `gemini-3.5-flash-lite`. Update earlier copies of `.env` that pin `TRIAGE_MODEL=gemini-2.5-flash`, or override the model settings when launching.

```bash
# From services/agents. The key is read from .env.
TRIAGE_PROVIDER=gemini REPORTING_TEXT_MODEL=gemini-3.8-flash REPORTING_LIVE_MODEL=gemini-3.8-live TRIAGE_MODEL=gemini-3.5-flash-lite .venv/bin/python -m anuvach_agents.serve

# Opt-in reporting → confirmation → A2A triage → simulated review.
REPORTING_TEXT_MODEL=gemini-3.8-flash TRIAGE_MODEL=gemini-3.5-flash-lite .venv/bin/python -m pytest --gemini -s tests/test_gemini_gate.py

# Opt-in real Live API audio transport. Requires espeak-ng and ffmpeg.
.venv/bin/python -m pytest --gemini-voice -s tests/test_gemini_voice.py
```

The tests use temporary databases. The voice test streams synthesized speech through the same localhost WebSocket used by the microphone, with audio kept in memory. Browser hardware, playback quality, barge-in and reconnect still need hands-on checks. In the browser, start the microphone, speak a synthetic incident, interrupt the agent during playback, then switch languages to exercise reconnection. Stop the microphone, review and correct the transcript, and confirm the draft explicitly. The text entry can be used when the voice connection drops.

Never expose port `8011` to the employee app or administrator dashboard. Later clients must use an authenticated application API. Stage 1-2 API adapters are only interfaces here and are intentionally unconnected.

## Local Views and Limits

- Employee: text fallback, language selector, native audio microphone controls, transcript, editable facts, and explicit confirmation. Raw audio is not persisted by the application.
- Admin: synthetic confirmed tickets, evidence-linked proposals, uncertainty, and simulated decisions.
- Diagnostics: responder labels, model IDs, connection/card state, A2A task IDs, real reporting tool calls and results, provider token counts when returned, and latency.
- Policy retrieval: unavailable. The unused `PolicyRetrievalPort` is an interface for Stage 4 only; there are no policy citations or AlloyDB/RAG work here.
- Language results and limits are recorded in the language matrix. Transcription quality is scored separately from text capture and audio transport.

See [the architecture and A2A sequence](../../docs/agents-architecture.md), [language matrix](../../docs/language-test-matrix.md), [experiment log](../../docs/experiment-log.md), and [deferred integration proposal](../../docs/agents-integration-plan.md).

## Local Flutter and React integration

Run the agents on loopback and point the existing API at the agent service. Start each command in its own terminal.

```bash
# From services/agents. Uses the key in the local .env.
TRIAGE_PROVIDER=gemini .venv/bin/python -m anuvach_agents.serve

# From the repository root.
AGENTS_BASE_URL=http://127.0.0.1:8000 npm run dev:api
LOCAL_API_URL=http://127.0.0.1:3000 npm run dev:admin

# From apps/mobile, with the Android emulator booted.
../../.tooling/flutter/bin/flutter test --no-pub integration_test/agent_reporting_test.dart -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

On a disposable API database, open the **STAGE3-ANDROID** report in the React queue and refresh its detail until the **AI proposal** is available. Accept the suggested severity and team or change either value and save the amendment. The review is audited separately from assignment, escalation, and ticket status. During peer outages the API keeps the ticket and retries pending triage.

For alternate ports, set `PORT` and `AGENTS_BASE_URL` for the API, `LOCAL_API_URL` for the React dev proxy, and `API_BASE_URL` for Flutter. The API owns all ticket persistence. The internal agent bridge handles reporting turns and validated A2A proposals. Use synthetic cases in this local integration. Voice remains in the standalone workbench.

### Stage 3 voice closeout

The Android reporting screen has an opt-in **Start voice** action. Fastify brokers bounded, in-memory PCM preview sessions to the existing Live agent. Android captures 16 kHz mono PCM16 and plays the PCM rate declared by Gemini. Interruption clears the playback queue. On connection failure, the employee can start a new voice session or keep typing. Only a finalized statement can be selected with **Use in draft**. The report text remains editable and ticket creation still requires the existing confirmation. Raw audio is streamed and released without file retention.

Report text supports English, Hindi, Tamil, Telugu, Bengali, Kannada, Malayalam, Urdu and Punjabi. Urdu uses right-to-left entry. The English synthesized speech fixture retained its incident fact. The other eight languages are labelled voice-limited and have text fallback. See the [language matrix](../../docs/language-test-matrix.md#stage-3-closeout-speech-assessment).

Before sending real employee reports, require authenticated employee and administrator identities, enforce report ownership on all employee reads and writes, protect admin review routes with role checks, bind voice sessions and idempotency keys to the authenticated owner, and keep A2A private. Use TLS, request quotas, clear voice consent, and documented audit and transcript retention controls. The current API is a loopback synthetic demo with unauthenticated routes. Stage 4 policy retrieval and deployment remain separate.
