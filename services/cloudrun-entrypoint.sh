#!/bin/bash
set -u

cd /app/services/agents
/opt/venv/bin/python -m anuvach_agents.serve &
agents_pid=$!

cleanup() {
  kill -TERM "$agents_pid" ${api_pid:+"$api_pid"} 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

# Wait for both private listeners before Cloud Run can route public requests.
/opt/venv/bin/python - <<'PY' || exit 1
import os
import time
from urllib.error import URLError
from urllib.request import urlopen

bridge = os.getenv("WORKBENCH_PORT", "8000")
triage = os.getenv("A2A_PORT", "8011")
urls = (
    f"http://127.0.0.1:{bridge}/openapi.json",
    f"http://127.0.0.1:{triage}/.well-known/agent-card.json",
)
deadline = time.monotonic() + 60
for url in urls:
    while True:
        try:
            with urlopen(url, timeout=1):
                break
        except (URLError, TimeoutError):
            if time.monotonic() >= deadline:
                raise SystemExit(f"Private agent listener failed to start: {url}")
            time.sleep(0.25)
PY

node /app/services/api/dist/src/server.js &
api_pid=$!

wait -n "$api_pid" "$agents_pid"
status=$?
exit "$status"
