#!/bin/sh

set -eu

WORKSPACE_DIR=${WORKSPACE_DIR:-/workspace}
GLOBAL_HOOKS_DIR=${GLOBAL_HOOKS_DIR:-/home/codex/.codex/githooks}

if [ -d "$WORKSPACE_DIR" ]; then
  cd "$WORKSPACE_DIR"
fi

AGENT_AUTHOR_NAME=${AGENT_AUTHOR_NAME:-Codex}
AGENT_AUTHOR_EMAIL=${AGENT_AUTHOR_EMAIL:-codex@openai.com}
git config --global user.name "$AGENT_AUTHOR_NAME"
git config --global user.email "$AGENT_AUTHOR_EMAIL"

mkdir -p "$GLOBAL_HOOKS_DIR"
cat >"$GLOBAL_HOOKS_DIR/commit-msg" <<'EOF'
#!/bin/sh
exec /usr/local/bin/agent-commit.sh --hook commit-msg "$@"
EOF
chmod +x "$GLOBAL_HOOKS_DIR/commit-msg"

git config --global core.hooksPath "$GLOBAL_HOOKS_DIR"
git config --global --unset-all commit.template >/dev/null 2>&1 || true

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  : "${PROMPTED_BY_NAME:=$(git config --get user.name || true)}"
  : "${PROMPTED_BY_EMAIL:=$(git config --get user.email || true)}"
  export PROMPTED_BY_NAME PROMPTED_BY_EMAIL

  : "${CODING_AGENT_NAME:=$AGENT_AUTHOR_NAME}"
  : "${CODING_AGENT_MODEL:=GPT-5}"
  : "${CODING_AGENT_MODEL_VERSION:=gpt-5}"
  : "${CODING_AGENT_MODEL_PARAMS:=approval-mode=${CODEX_APPROVAL_MODE:-manual};sandbox=${CODEX_SANDBOX_MODE:-workspace-write}}"
  export CODING_AGENT_NAME CODING_AGENT_MODEL CODING_AGENT_MODEL_VERSION CODING_AGENT_MODEL_PARAMS
fi

exec "$@"
