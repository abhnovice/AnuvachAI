#!/bin/bash
set -u

cd /app/services/agents
/opt/venv/bin/python -m anuvach_agents.serve &
agents_pid=$!

node /app/services/api/dist/src/server.js &
api_pid=$!

cleanup() {
  kill -TERM "$api_pid" "$agents_pid" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

wait -n "$api_pid" "$agents_pid"
status=$?
exit "$status"