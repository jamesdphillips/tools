#!/bin/sh

set -eu

WORKSPACE_DIR=${WORKSPACE_DIR:-/workspace}

if [ -d "$WORKSPACE_DIR" ]; then
  cd "$WORKSPACE_DIR"
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  : "${PROMPTED_BY_NAME:=$(git config --get user.name || true)}"
  : "${PROMPTED_BY_EMAIL:=$(git config --get user.email || true)}"
  export PROMPTED_BY_NAME PROMPTED_BY_EMAIL

  git config --global core.hooksPath "$WORKSPACE_DIR/.githooks"
  git config --global commit.template "$WORKSPACE_DIR/.gitmessage.codex"

  AGENT_AUTHOR_NAME=${AGENT_AUTHOR_NAME:-Codex}
  AGENT_AUTHOR_EMAIL=${AGENT_AUTHOR_EMAIL:-codex@users.noreply.local}
  git config --global user.name "$AGENT_AUTHOR_NAME"
  git config --global user.email "$AGENT_AUTHOR_EMAIL"

  : "${CODING_AGENT_NAME:=$AGENT_AUTHOR_NAME}"
  : "${CODING_AGENT_MODEL:=GPT-5}"
  : "${CODING_AGENT_MODEL_VERSION:=gpt-5}"
  : "${CODING_AGENT_MODEL_PARAMS:=approval-mode=${CODEX_APPROVAL_MODE:-manual};sandbox=${CODEX_SANDBOX_MODE:-workspace-write}}"
  export CODING_AGENT_NAME CODING_AGENT_MODEL CODING_AGENT_MODEL_VERSION CODING_AGENT_MODEL_PARAMS
fi

exec "$@"
