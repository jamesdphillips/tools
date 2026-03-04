#!/usr/bin/env bash

set -euo pipefail

script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_path/agent-sandbox/lib.sh"

export AGENT_KIND="claude"
export AGENT_CONTEXT_DIR="$script_path/agent-sandbox"
export AGENT_SANDBOX_IMAGE="${CLAUDE_SANDBOX_IMAGE:-claude-sandbox:latest}"
export AGENT_NPM_PACKAGE="${CLAUDE_NPM_PACKAGE:-@anthropic-ai/claude-code}"

export AGENT_AUTHOR_NAME="${AGENT_AUTHOR_NAME:-Claude}"
export AGENT_AUTHOR_EMAIL="${AGENT_AUTHOR_EMAIL:-claude@anthropic.com}"
export AGENT_NAME="${CODING_AGENT_NAME:-${AGENT_NAME:-Claude Code}}"
export AGENT_MODEL="${CODING_AGENT_MODEL:-${AGENT_MODEL:-Claude}}"
export AGENT_MODEL_VERSION="${CODING_AGENT_MODEL_VERSION:-${AGENT_MODEL_VERSION:-claude-code}}"
export AGENT_APPROVAL_MODE="${CLAUDE_APPROVAL_MODE:-${AGENT_APPROVAL_MODE:-never}}"
export AGENT_SANDBOX_MODE="${CLAUDE_SANDBOX_MODE:-${AGENT_SANDBOX_MODE:-danger-full-access}}"
export AGENT_MODEL_PARAMS="${CODING_AGENT_MODEL_PARAMS:-${AGENT_MODEL_PARAMS:-approval-mode=$AGENT_APPROVAL_MODE;sandbox=$AGENT_SANDBOX_MODE}}"
export AGENT_DEFAULT_CMD="${AGENT_DEFAULT_CMD:-claude}"

export AGENT_HOME_DIR="${AGENT_HOME_DIR:-/home/codex/.codex}"
export AGENT_USER="${AGENT_USER:-codex}"

export AGENT_FORWARD_ENV_VARS="ANTHROPIC_API_KEY ANTHROPIC_BASE_URL OPENAI_API_KEY OPENAI_BASE_URL OPENAI_ORG_ID OPENAI_PROJECT_ID"
export AGENT_FORWARD_ENV_PREFIXES="CLAUDE_"
export AGENT_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-${CODEX_SKILLS_DIR:-$HOME/.codex/skills}}"
export AGENT_AGENTS_FILE="${CLAUDE_AGENTS_FILE:-${CODEX_AGENTS_FILE:-$HOME/.codex/AGENTS.md}}"

agent_sandbox_main "$@"
