#!/bin/sh

set -eu

script_path=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$script_path/agent-sandbox/lib.sh"

export AGENT_KIND="codex"
export AGENT_SCRIPT_PATH="$script_path"
export AGENT_CONTEXT_DIR="$script_path/agent-sandbox"
export AGENT_SANDBOX_IMAGE="${CODEX_SANDBOX_IMAGE:-codex-sandbox:latest}"
export AGENT_NPM_PACKAGE="${CODEX_NPM_PACKAGE:-@openai/codex}"

export AGENT_AUTHOR_NAME="${AGENT_AUTHOR_NAME:-Codex}"
export AGENT_AUTHOR_EMAIL="${AGENT_AUTHOR_EMAIL:-codex@openai.com}"
export AGENT_NAME="${CODING_AGENT_NAME:-${AGENT_NAME:-Codex}}"
export AGENT_MODEL="${CODING_AGENT_MODEL:-${AGENT_MODEL:-GPT-5}}"
export AGENT_MODEL_VERSION="${CODING_AGENT_MODEL_VERSION:-${AGENT_MODEL_VERSION:-gpt-5}}"
export AGENT_APPROVAL_MODE="${CODEX_APPROVAL_MODE:-${AGENT_APPROVAL_MODE:-never}}"
export AGENT_SANDBOX_MODE="${CODEX_SANDBOX_MODE:-${AGENT_SANDBOX_MODE:-danger-full-access}}"
export AGENT_MODEL_PARAMS="${CODING_AGENT_MODEL_PARAMS:-${AGENT_MODEL_PARAMS:-approval-mode=$AGENT_APPROVAL_MODE;sandbox=$AGENT_SANDBOX_MODE}}"
export AGENT_DEFAULT_CMD="${AGENT_DEFAULT_CMD:-codex}"

export AGENT_HOME_DIR="${AGENT_HOME_DIR:-/home/codex/.codex}"
export AGENT_USER="${AGENT_USER:-codex}"

export AGENT_FORWARD_ENV_VARS="OPENAI_API_KEY OPENAI_BASE_URL OPENAI_ORG_ID OPENAI_PROJECT_ID"
export AGENT_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
export AGENT_AGENTS_FILE="${CODEX_AGENTS_FILE:-$HOME/.codex/AGENTS.md}"

agent_sandbox_main "$@"
