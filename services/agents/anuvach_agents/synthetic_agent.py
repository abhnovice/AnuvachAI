from __future__ import annotations

from collections.abc import AsyncGenerator

from google.adk.agents import BaseAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events import Event
from google.genai import types

from .contracts import (
    ReceivingTeam,
    Severity,
    TriageProposal,
    TriageReason,
)
from .triage_agent import parse_confirmed_report_text


class SyntheticTriageAgent(BaseAgent):
    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        parts = ctx.user_content.parts if ctx.user_content else []
        text = "".join(part.text or "" for part in parts)
        report = parse_confirmed_report_text(text)
        proposal = TriageProposal(
            proposal_id=f"SYN-P-{report.report_id}-r{report.revision}",
            report_id=report.report_id,
            report_revision=report.revision,
            incident_type=report.incident_type,
            proposed_severity=Severity.UNASSESSED,
            proposed_team=ReceivingTeam.UNKNOWN,
            reasons=[
                TriageReason(
                    text=f"Employee-reported fact: {fact.text}",
                    fact_ids=[fact.fact_id],
                )
                for fact in report.facts
            ],
            evidence_references=[
                {
                    "fact_id": fact.fact_id,
                    "explains": "Synthetic responder echoes a confirmed report fact.",
                }
                for fact in report.facts
            ],
            unknowns=report.unknowns or ["No further facts were provided."],
            recommended_next_questions=[
                "What, if anything, did you do after receiving the request?"
            ],
            human_review_required=True,
        )
        yield Event(
            author=self.name,
            content=types.Content(
                role="model", parts=[types.Part.from_text(text=proposal.model_dump_json())]
            ),
        )


def build_synthetic_triage_agent() -> SyntheticTriageAgent:
    return SyntheticTriageAgent(
        name="synthetic_admin_triage_agent",
        description=(
            "Test-only synthetic responder for confirmed-report A2A contract checks."
        ),
    )