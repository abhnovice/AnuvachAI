from __future__ import annotations

from datetime import UTC, datetime

from fastapi.testclient import TestClient

from anuvach_agents.a2a_client import A2AResult
from anuvach_agents.contracts import (
    EvidenceReference,
    IncidentType,
    ReceivingTeam,
    Severity,
    TriageProposal,
    TriageReason,
)
from anuvach_agents.fake_adapters import SQLiteFakeAdapters
from anuvach_agents.workbench import create_app


def test_text_draft_preserves_original_and_urdu_direction(tmp_path) -> None:
    client = TestClient(create_app(SQLiteFakeAdapters(tmp_path / "workbench.sqlite")))
    response = client.post(
        "/api/drafts",
        json={
            "text": "ایک نامعلوم شخص نے کوڈ مانگا۔",
            "language": "ur",
            "incident_type": "support_call",
        },
    )
    assert response.status_code == 200
    draft = response.json()["draft"]
    assert draft["transcript"][0]["original_text"] == "ایک نامعلوم شخص نے کوڈ مانگا۔"
    assert draft["facts"][0]["source"] == "employee_statement"
    assert response.json()["policy_grounding"] == "unavailable"


def test_decline_confirmation_retry_trouble_and_admin_ack(tmp_path) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "workbench.sqlite")
    calls = 0

    async def triage(report):
        nonlocal calls
        calls += 1
        if calls == 1:
            raise ConnectionError("test peer outage")
        fact = report.facts[0]
        return A2AResult(
            proposal=TriageProposal(
                proposal_id="P-WB-1",
                report_id=report.report_id,
                report_revision=report.revision,
                incident_type=IncidentType.SUPPORT_CALL,
                proposed_severity=Severity.UNASSESSED,
                proposed_team=ReceivingTeam.UNKNOWN,
                reasons=[TriageReason(text="The report states a request.", fact_ids=[fact.fact_id])],
                evidence_references=[
                    EvidenceReference(fact_id=fact.fact_id, explains="Reported fact")
                ],
                human_review_required=True,
            ),
            task_id="TASK-WB-1",
            latency_ms=7.0,
            agent_card_url="http://127.0.0.1:8011/.well-known/agent-card.json",
        )

    client = TestClient(create_app(adapters, triage_call=triage))
    draft_response = client.post(
        "/api/drafts",
        json={
            "text": "A caller asked me to install remote access software.",
            "language": "en",
            "incident_type": "support_call",
        },
    )
    report_id = draft_response.json()["draft"]["report_id"]
    declined = client.post(
        f"/api/drafts/{report_id}/confirm",
        json={"confirmed": False, "idempotency_key": "workbench-key-1"},
    )
    assert declined.status_code == 400
    assert client.get("/api/tickets").json() == []

    stale = client.post(
        f"/api/drafts/{report_id}/confirm",
        json={"confirmed": True, "revision": 2, "idempotency_key": "workbench-key-1"},
    )
    assert stale.status_code == 409
    assert client.get("/api/tickets").json() == []

    body = {"confirmed": True, "revision": 1, "idempotency_key": "workbench-key-1"}
    first = client.post(f"/api/drafts/{report_id}/confirm", json=body).json()
    retried = client.post(f"/api/drafts/{report_id}/confirm", json=body).json()
    assert first["ticket_id"] == retried["ticket_id"]
    assert first["acknowledged"] is True

    pending = client.post(f"/api/tickets/{first['ticket_id']}/triage", json={"retry": True}).json()
    assert pending["status"] == "pending"
    assert pending["ticket_intact"] is True
    assert pending["human_review_required"] is True
    assert client.post(
        f"/api/tickets/{first['ticket_id']}/decision", json={"decision": "accept"}
    ).status_code == 409
    completed = client.post(f"/api/tickets/{first['ticket_id']}/triage", json={"retry": True}).json()
    assert completed["status"] == "completed"
    assert len(client.get("/api/tickets").json()) == 1

    decision = client.post(
        f"/api/tickets/{first['ticket_id']}/decision",
        json={"decision": "accept", "details": {}},
    ).json()
    assert decision["acknowledged"] is True
    assert decision["decision_id"].startswith("DEC-")

    restarted_client = TestClient(
        create_app(SQLiteFakeAdapters(tmp_path / "workbench.sqlite"))
    )
    diagnostics = restarted_client.get("/api/diagnostics").json()
    assert diagnostics["last_a2a"]["task_id"] == "TASK-WB-1"
    assert diagnostics["last_a2a"]["correlation_id"].startswith("CORR-")
    assert any(item["tool"] == "triage_a2a_succeeded" for item in diagnostics["tool_calls"])


def test_confirmation_bypass_instruction_does_not_create_ticket(tmp_path) -> None:
    adapters = SQLiteFakeAdapters(tmp_path / "bypass.sqlite")
    client = TestClient(create_app(adapters))
    result = client.post("/api/scenarios/bypass-attempt", json={}).json()
    draft = result["draft"]
    declined = client.post(
        f"/api/drafts/{draft['report_id']}/confirm",
        json={"confirmed": False, "idempotency_key": "bypass-key-1"},
    )
    assert declined.status_code == 400
    assert client.get("/api/tickets").json() == []


def test_correction_scenario_keeps_original_and_corrected_text(tmp_path) -> None:
    client = TestClient(create_app(SQLiteFakeAdapters(tmp_path / "correction.sqlite")))
    result = client.post("/api/scenarios/interrupted-correction", json={}).json()
    draft = result["draft"]
    turn = draft["transcript"][0]
    assert turn["original_text"] == "The caller asked me to install QuickHelp."
    assert turn["corrected_text"] == "The caller asked me to install QuickAssist."
    assert draft["facts"][0]["text"] == turn["corrected_text"]


def test_live_voice_reports_missing_key_without_reconnecting(tmp_path, monkeypatch) -> None:
    monkeypatch.delenv("GOOGLE_API_KEY", raising=False)
    client = TestClient(create_app(SQLiteFakeAdapters(tmp_path / "voice.sqlite")))
    with client.websocket_connect("/api/live") as websocket:
        response = websocket.receive_json()
    assert response["type"] == "error"
    assert "not configured" in response["message"]


def test_language_switch_and_required_synthetic_scenarios(tmp_path) -> None:
    client = TestClient(create_app(SQLiteFakeAdapters(tmp_path / "scenarios.sqlite")))
    first = client.post(
        "/api/drafts",
        json={"text": "मुझे एक कॉल आया।", "language": "hi", "incident_type": "support_call"},
    ).json()["draft"]
    switched = client.post(
        "/api/drafts",
        json={
            "text": "The caller asked for a pairing code.",
            "language": "en",
            "incident_type": "support_call",
            "report_id": first["report_id"],
        },
    ).json()["draft"]
    assert switched["preferred_language"] == "en"
    assert [turn["language"] for turn in switched["transcript"]] == ["hi", "en"]

    suspicious = client.post("/api/scenarios/support-call", json={}).json()["draft"]
    assert "remote-access" in suspicious["facts"][0]["text"]
    assert "pairing code" in suspicious["facts"][0]["text"]

    mistaken = client.post("/api/scenarios/mistaken-report", json={}).json()["draft"]
    assert mistaken["incident_type"] == "mistaken_report"

    limited = client.post("/api/scenarios/limited-observation", json={}).json()["draft"]
    assert all(fact["source"] == "employee_statement" for fact in limited["facts"])

def test_voice_ticket_tool_returns_a_draft_without_creating_a_ticket(tmp_path, monkeypatch) -> None:
    from google.adk.events import Event
    from google.adk.runners import Runner
    from google.genai import types

    async def run_live(runner, **kwargs):
        assert kwargs["run_config"].realtime_input_config is None
        tool, = runner.agent.tools
        assert tool.__name__ == "prepare_ticket"
        payload = tool(
            "Someone asked for an ExampleApp code over chat.",
            "ExampleApp", "", "suspicious_message", ["Sender identity"],
        )
        yield Event(
            author=runner.agent.name,
            content=types.Content(
                role="user",
                parts=[types.Part.from_function_response(name=tool.__name__, response=payload)],
            ),
        )

    monkeypatch.setenv("GOOGLE_API_KEY", "fixture")
    monkeypatch.setattr(Runner, "run_live", run_live)
    client = TestClient(create_app(SQLiteFakeAdapters(tmp_path / "voice-ticket.sqlite")))
    with client.websocket_connect("/api/live?preview=1&ticket_draft=1") as websocket:
        assert websocket.receive_json()["state"] == "Microphone stream open"
        event = websocket.receive_json()
        assert event["type"] == "ticket_draft"
        assert event["draft"]["app_name"] == "ExampleApp"
        assert event["draft"]["unknowns"] == ["Sender identity"]
        assert websocket.receive()["type"] == "websocket.close"
    assert client.get("/api/tickets").json() == []


def test_live_opening_and_closing_cues_are_spoken_without_drafting(tmp_path, monkeypatch):
    import base64
    import time

    from google.adk.events import Event
    from google.adk.runners import Runner
    from google.genai import types

    monkeypatch.setenv("GOOGLE_API_KEY", "fake-test-only")
    cues = []

    async def simulated_live(self, *, live_request_queue, **kwargs):
        while True:
            request = await live_request_queue.get()
            if request.close:
                return
            if request.content:
                cue = request.content.parts[0].text
                cues.append(cue)
                yield Event(author="agent", content=types.Content(parts=[
                    types.Part.from_bytes(data=b"\x00\x00", mime_type="audio/pcm;rate=24000"),
                ]), turn_complete=True)
                if cue.startswith(("[App closing cue]", "[App resume cue]")):
                    return

    monkeypatch.setattr(Runner, "run_live", simulated_live)
    store = SQLiteFakeAdapters(tmp_path / "voice-cues.sqlite")
    with TestClient(create_app(store)) as client:
        with client.websocket_connect("/api/live?language=hi&preview=1") as voice:
            assert voice.receive_json()["state"] == "Microphone stream open"
            voice.send_json({"type": "greet"})
            assert voice.receive_json()["type"] == "audio"
            assert voice.receive_json()["state"] == "listening"
            voice.send_json({"type": "finish"})
            assert voice.receive_json()["type"] == "audio"
            assert voice.receive_json()["state"] == "closed_turn"
            assert voice.receive()["type"] == "websocket.close"
        with client.websocket_connect("/api/live?language=en&preview=1") as voice:
            assert voice.receive_json()["state"] == "Microphone stream open"
            voice.send_json({"type": "greet"})
            voice.send_json({
                "type": "audio",
                "data": base64.b64encode(b"\x00\x04" * 320).decode(),
            })
            time.sleep(1.65)
            voice.send_json({"type": "finish"})
            assert voice.receive_json()["type"] == "audio"
            assert voice.receive_json()["state"] == "closed_turn"
            assert voice.receive()["type"] == "websocket.close"
        with client.websocket_connect("/api/live?language=en&preview=1") as voice:
            assert voice.receive_json()["voice_context"] is True
            voice.send_json({
                "type": "restore",
                "context": [{"speaker": "employee", "text": "A caller asked for a code."}],
            })
            assert voice.receive_json()["type"] == "audio"
            assert voice.receive_json()["state"] == "listening"
            assert voice.receive()["type"] == "websocket.close"
    assert len(cues) == 4
    assert "A caller asked for a code." in cues[3]
    assert "सब ठीक है?" in cues[0]
    assert "latest spoken language" in cues[1]
    assert store.list_confirmed_tickets() == []


def test_reporting_uses_saved_turns_on_a_fresh_session(tmp_path, monkeypatch):
    from google.adk.events import Event
    from google.adk.runners import Runner
    from google.genai import types

    monkeypatch.setenv("GOOGLE_API_KEY", "fake-test-only")
    seen = []

    async def run_async(runner, *, user_id, session_id, new_message, **kwargs):
        session = await runner.session_service.get_session(
            app_name=runner.app_name, user_id=user_id, session_id=session_id,
        )
        seen.append([(event.content.role, event.content.parts[0].text) for event in session.events])
        assert new_message.parts[0].text.endswith("It happened this morning.")
        yield Event(author=runner.agent.name, content=types.Content(
            role="model", parts=[types.Part.from_text(text="Which app was used?")],
        ))

    monkeypatch.setattr(Runner, "run_async", run_async)
    with TestClient(create_app(SQLiteFakeAdapters(tmp_path / "saved-chat.sqlite"))) as client:
        request = {
            "sessionId": "c5a6866b-69ed-4d14-baf3-32d43093dfa0", "language": "en",
            "text": "It happened this morning.",
            "context": [
                {"speaker": "employee", "text": "A caller asked for a code."},
                {"speaker": "agent", "text": "When did it happen?"},
            ],
        }
        response = client.post("/internal/reporting/turn", json=request)
        assert response.status_code == 200
        assert response.json()["reply"] == "Which app was used?"
        response = client.post("/internal/reporting/turn", json={**request, "context": []})
        assert response.status_code == 200
    assert seen == [[("user", "A caller asked for a code."), ("model", "When did it happen?")], []]


def test_description_translation_uses_source_text_separately(tmp_path, monkeypatch):
    from types import SimpleNamespace
    from google import genai

    class Translator:
        async def __aenter__(self):
            return SimpleNamespace(models=SimpleNamespace(generate_content=self.translate))

        async def __aexit__(self, *exc):
            return None

        async def translate(self, *, contents, config, **kwargs):
            assert contents == "किसी ने कोड माँगा।"
            assert "English" in config.system_instruction
            return SimpleNamespace(text="Someone requested a code.")

    monkeypatch.setenv("GOOGLE_API_KEY", "fake-test-only")
    monkeypatch.setattr(genai, "Client", lambda: SimpleNamespace(aio=Translator()))
    with TestClient(create_app(SQLiteFakeAdapters(tmp_path / "translation.sqlite"))) as client:
        response = client.post(
            "/internal/reporting/translate",
            json={"language": "en", "text": "किसी ने कोड माँगा।"},
        )
    assert response.status_code == 200
    assert response.json() == {"translation": "Someone requested a code."}
