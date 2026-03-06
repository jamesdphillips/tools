#!/bin/sh

set -eu

WORKSPACE_DIR=${WORKSPACE_DIR:-/workspace}
AGENT_HOME_DIR=${AGENT_HOME_DIR:-/home/codex/.codex}
GLOBAL_HOOKS_DIR=${GLOBAL_HOOKS_DIR:-$AGENT_HOME_DIR/githooks}

if [ -d "$WORKSPACE_DIR" ]; then
  cd "$WORKSPACE_DIR"
fi

AGENT_AUTHOR_NAME=${AGENT_AUTHOR_NAME:-Codex}
AGENT_AUTHOR_EMAIL=${AGENT_AUTHOR_EMAIL:-codex@openai.com}
AGENT_APPROVAL_MODE=${AGENT_APPROVAL_MODE:-${CODEX_APPROVAL_MODE:-never}}
AGENT_SANDBOX_MODE=${AGENT_SANDBOX_MODE:-${CODEX_SANDBOX_MODE:-danger-full-access}}
AGENT_DEFAULT_CMD=${AGENT_DEFAULT_CMD:-codex}
AGENT_KIND=${AGENT_KIND:-codex}

mkdir -p "$GLOBAL_HOOKS_DIR"
cat >"$GLOBAL_HOOKS_DIR/commit-msg" <<'HOOK'
#!/bin/sh
exec /usr/local/bin/agent-commit.sh --hook commit-msg "$@"
HOOK
chmod +x "$GLOBAL_HOOKS_DIR/commit-msg"

git config --global core.hooksPath "$GLOBAL_HOOKS_DIR"
git config --global --unset-all commit.template >/dev/null 2>&1 || true

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  : "${PROMPTED_BY_NAME:=$(git config --local --get user.name || git config --get user.name || true)}"
  : "${PROMPTED_BY_EMAIL:=$(git config --local --get user.email || git config --get user.email || true)}"
  export PROMPTED_BY_NAME PROMPTED_BY_EMAIL

  : "${CODING_AGENT_NAME:=${AGENT_NAME:-$AGENT_AUTHOR_NAME}}"
  : "${CODING_AGENT_MODEL:=${AGENT_MODEL:-unknown}}"
  : "${CODING_AGENT_MODEL_VERSION:=${AGENT_MODEL_VERSION:-$CODING_AGENT_MODEL}}"
  : "${CODING_AGENT_MODEL_PARAMS:=${AGENT_MODEL_PARAMS:-approval-mode=$AGENT_APPROVAL_MODE;sandbox=$AGENT_SANDBOX_MODE}}"
  export CODING_AGENT_NAME CODING_AGENT_MODEL CODING_AGENT_MODEL_VERSION CODING_AGENT_MODEL_PARAMS
fi

git config --global user.name "$AGENT_AUTHOR_NAME"
git config --global user.email "$AGENT_AUTHOR_EMAIL"

if [ "$#" -eq 0 ]; then
  set -- "$AGENT_DEFAULT_CMD"
fi

if [ -n "${AGENT_NPM_PACKAGE:-}" ]; then
  npm install -g --no-fund "$AGENT_NPM_PACKAGE" >/dev/null 2>&1 || true
fi

if [ "$1" = "codex" ] || [ "$AGENT_KIND" = "codex" ] && [ "$1" = "$AGENT_DEFAULT_CMD" ]; then
  has_approval_mode=0
  has_sandbox_mode=0
  prev=
  for arg in "$@"; do
    if [ "$prev" = "--ask-for-approval" ]; then
      has_approval_mode=1
    fi
    if [ "$prev" = "--sandbox" ]; then
      has_sandbox_mode=1
    fi
    case "$arg" in
      --ask-for-approval=*)
        has_approval_mode=1
        ;;
      --sandbox|--sandbox=*)
        has_sandbox_mode=1
        ;;
    esac
    prev="$arg"
  done

  if [ "$has_approval_mode" -eq 0 ]; then
    set -- "$@" --ask-for-approval "$AGENT_APPROVAL_MODE"
  fi
  if [ "$has_sandbox_mode" -eq 0 ]; then
    set -- "$@" --sandbox "$AGENT_SANDBOX_MODE"
  fi
fi

exec "$@"
