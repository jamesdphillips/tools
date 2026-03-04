#!/bin/sh

set -eu

script_path=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$script_path/agent-sandbox/lib.sh"

export AGENT_KIND="opencode"
export AGENT_SCRIPT_PATH="$script_path"
export AGENT_CONTEXT_DIR="$script_path/agent-sandbox"
export AGENT_SANDBOX_IMAGE="${OPENCODE_SANDBOX_IMAGE:-opencode-sandbox:latest}"
export AGENT_NPM_PACKAGE="${OPENCODE_NPM_PACKAGE:-opencode-ai}"

export AGENT_AUTHOR_NAME="${AGENT_AUTHOR_NAME:-OpenCode}"
export AGENT_AUTHOR_EMAIL="${AGENT_AUTHOR_EMAIL:-opencode@opencode.ai}"
export AGENT_NAME="${CODING_AGENT_NAME:-${AGENT_NAME:-OpenCode}}"
export AGENT_MODEL="${CODING_AGENT_MODEL:-${AGENT_MODEL:-OpenCode}}"
export AGENT_MODEL_VERSION="${CODING_AGENT_MODEL_VERSION:-${AGENT_MODEL_VERSION:-opencode-ai}}"
export AGENT_APPROVAL_MODE="${OPENCODE_APPROVAL_MODE:-${AGENT_APPROVAL_MODE:-never}}"
export AGENT_SANDBOX_MODE="${OPENCODE_SANDBOX_MODE:-${AGENT_SANDBOX_MODE:-danger-full-access}}"
export AGENT_MODEL_PARAMS="${CODING_AGENT_MODEL_PARAMS:-${AGENT_MODEL_PARAMS:-approval-mode=$AGENT_APPROVAL_MODE;sandbox=$AGENT_SANDBOX_MODE}}"
export AGENT_DEFAULT_CMD="${AGENT_DEFAULT_CMD:-opencode}"

export AGENT_HOME_DIR="${AGENT_HOME_DIR:-/home/codex/.codex}"
export AGENT_USER="${AGENT_USER:-codex}"

export AGENT_FORWARD_ENV_PREFIXES="OPENCODE_"
export AGENT_SKILLS_DIR="${OPENCODE_SKILLS_DIR:-${CODEX_SKILLS_DIR:-$HOME/.codex/skills}}"
export AGENT_AGENTS_FILE="${OPENCODE_AGENTS_FILE:-${CODEX_AGENTS_FILE:-$HOME/.codex/AGENTS.md}}"

agent_sandbox_main "$@"
