from __future__ import annotations

import os

from google.adk.a2a.utils.agent_to_a2a import to_a2a

from .synthetic_agent import build_synthetic_triage_agent
from .triage_agent import build_triage_agent


HOST = os.getenv("A2A_HOST", "127.0.0.1")
PORT = int(os.getenv("A2A_PORT", "8011"))
TRIAGE_PROVIDER = os.getenv("TRIAGE_PROVIDER", "synthetic").lower()
root_agent = (
    build_triage_agent()
    if TRIAGE_PROVIDER == "gemini"
    else build_synthetic_triage_agent()
)
a2a_app = to_a2a(root_agent, host=HOST, port=PORT)
