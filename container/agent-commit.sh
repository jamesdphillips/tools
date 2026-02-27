#!/usr/bin/env bash

set -euo pipefail

for arg in "$@"; do
  if [[ "$arg" == "--no-verify" ]]; then
    echo "error: --no-verify is blocked for agent commits." >&2
    exit 1
  fi
done

exec git \
  -c "user.name=${AGENT_AUTHOR_NAME:-Codex}" \
  -c "user.email=${AGENT_AUTHOR_EMAIL:-codex@users.noreply.local}" \
  commit "$@"
