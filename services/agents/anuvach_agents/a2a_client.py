from __future__ import annotations

import json
import os
import time
import uuid
from dataclasses import dataclass

from pydantic import ValidationError

from google.adk.agents.remote_a2a_agent import RemoteA2aAgent
from google.adk.artifacts import InMemoryArtifactService
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

from .contracts import ConfirmedReport, TriageProposal, validate_proposal_for_report


class InvalidTriageOutput(ValueError):
    pass


@dataclass(frozen=True)
class A2AResult:
    proposal: TriageProposal
    task_id: str | None
    latency_ms: float
    agent_card_url: str
    responder: str | None = None


async def send_confirmed_report(
    report: ConfirmedReport,
    *,
    agent_card_url: str | None = None,
) -> A2AResult:
    if not isinstance(report, ConfirmedReport):
        raise TypeError("A2A triage accepts only a ConfirmedReport")
    card_url = agent_card_url or os.getenv(
        "TRIAGE_AGENT_CARD_URL", "http://127.0.0.1:8011/.well-known/agent-card.json"
    )
    remote = RemoteA2aAgent(
        name="remote_admin_triage_agent",
        description="Remote A2A endpoint for confirmed-report triage.",
        agent_card=card_url,
        timeout=35,
    )
    app_name = "anuvach_reporting_coordinator"
    user_id = "local-workbench"
    session_id = str(uuid.uuid4())
    session_service = InMemorySessionService()
    runner = Runner(
        app_name=app_name,
        agent=remote,
        artifact_service=InMemoryArtifactService(),
        session_service=session_service,
    )
    await session_service.create_session(
        app_name=app_name,
        user_id=user_id,
        session_id=session_id,
    )
    message = json.dumps(report.model_dump(mode="json"), ensure_ascii=False)
    started = time.perf_counter()
    response_text = ""
    task_id: str | None = None
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id,
        new_message=types.Content(
            role="user", parts=[types.Part.from_text(text=message)]
        ),
    ):
        if event.error_code or event.error_message:
            raise ConnectionError("A2A peer returned an error")
        if event.content:
            event_text = "".join(
                part.text or "" for part in event.content.parts or []
            )
            if event_text:
                response_text = event_text
        metadata = getattr(event, "custom_metadata", None)
        if isinstance(metadata, dict) and isinstance(metadata.get("a2a:task_id"), str):
            task_id = metadata["a2a:task_id"]
    try:
        proposal = TriageProposal.model_validate_json(response_text)
    except ValidationError as error:
        raise InvalidTriageOutput("Peer did not return a structured triage proposal") from error
    try:
        validate_proposal_for_report(proposal, report)
    except ValueError as error:
        raise InvalidTriageOutput(str(error)) from error
    return A2AResult(
        proposal=proposal,
        task_id=task_id,
        latency_ms=(time.perf_counter() - started) * 1000,
        agent_card_url=card_url,
        responder="synthetic responder" if proposal.proposal_id.startswith("SYN-P-") else "Gemini responder",
    )