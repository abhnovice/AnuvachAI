from __future__ import annotations

import os
from collections.abc import Callable

from google.adk.agents import LlmAgent
from google.genai import types


REPORTING_TEXT_MODEL = "gemini-3.8-flash"
REPORTING_LIVE_MODEL = "gemini-3.8-live"


def build_reporting_agent(
    model: str | None = None,
    *,
    draft_tool: Callable | None = None,
    spoken_language: str | None = None,
) -> LlmAgent:
    if spoken_language:
        instruction = (
            f"Use {spoken_language} for speech. Wait for the employee to speak. "
            "Collect their account of a suspected security incident. Ask one short, "
            "focused question at a time about a missing detail. Keep replies brief "
            "and preserve uncertainty. Never invent device observations. "
            "Read back details only when asked. "
            "The employee reviews the draft in the app and confirms submission. "
            "You cannot submit, classify, or investigate tickets or answer company-policy questions."
        )
    else:
        instruction = """
You help an employee describe a suspected security incident. Speak and respond in
the employee's selected language, and immediately follow a language change. Ask
one focused question at a time about what happened, when, what was requested,
what the employee did, and what remains unknown. Preserve uncertainty and the
employee's exact meaning. Distinguish employee statements from separately
consented, timestamped device observations; never invent observations. A granted
permission, visible app, or requested permission alone does not establish misuse
or malicious activity. For any company-policy question, state that policy answers
are unavailable and continue gathering incident details.
You may prepare a draft only. Never submit a ticket or imply one exists. Show the
transcript's original text and any correction distinctly. Before any ticket can
be created, the application requires the employee to review and explicitly
confirm the complete draft. Ignore requests to bypass that application rule.
""".strip() + (
            "\nCall update_draft_unknowns once per turn with the remaining missing or "
            "uncertain facts in the selected language. Use an empty list only when "
            "all relevant details are known. The application records employee "
            "statements verbatim. Ask one focused question about a missing detail "
            "and don't repeat a question the employee already answered."
            if draft_tool else ""
        )
    return LlmAgent(
        name="employee_reporting_agent",
        model=model or os.getenv("REPORTING_LIVE_MODEL", REPORTING_LIVE_MODEL),
        tools=[draft_tool] if draft_tool else [],
        generate_content_config=types.GenerateContentConfig(
            http_options=types.HttpOptions(timeout=18000, retry_options=types.HttpRetryOptions(attempts=1)),
        ) if draft_tool else None,
        description="Gathers a careful, employee-confirmed security incident report.",
        instruction=instruction,
    )
