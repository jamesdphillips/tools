#!/bin/sh

set -eu

WORKSPACE_DIR=${WORKSPACE_DIR:-/workspace}
GLOBAL_HOOKS_DIR=${GLOBAL_HOOKS_DIR:-/home/codex/.codex/githooks}
CODEX_HOME=${CODEX_HOME:-/home/codex/.codex}
GLOBAL_SKILLS_DIR=${GLOBAL_SKILLS_DIR:-$CODEX_HOME/skills}
BUNDLED_SKILLS_DIR=${BUNDLED_SKILLS_DIR:-/usr/local/share/codex/skills}
RUNTIME_CODEX_HOME=${RUNTIME_CODEX_HOME:-/tmp/codex-home}

if [ -d "$WORKSPACE_DIR" ]; then
  cd "$WORKSPACE_DIR"
fi

AGENT_AUTHOR_NAME=${AGENT_AUTHOR_NAME:-Codex}
AGENT_AUTHOR_EMAIL=${AGENT_AUTHOR_EMAIL:-codex@openai.com}
CODEX_APPROVAL_MODE=${CODEX_APPROVAL_MODE:-never}
CODEX_SANDBOX_MODE=${CODEX_SANDBOX_MODE:-danger-full-access}

mkdir -p "$GLOBAL_HOOKS_DIR"
cat >"$GLOBAL_HOOKS_DIR/commit-msg" <<'EOF'
#!/bin/sh
exec /usr/local/bin/agent-commit.sh --hook commit-msg "$@"
EOF
chmod +x "$GLOBAL_HOOKS_DIR/commit-msg"

git config --global core.hooksPath "$GLOBAL_HOOKS_DIR"
git config --global --unset-all commit.template >/dev/null 2>&1 || true

if mkdir -p "$GLOBAL_SKILLS_DIR" 2>/dev/null && [ -w "$GLOBAL_SKILLS_DIR" ]; then
  EFFECTIVE_SKILLS_DIR="$GLOBAL_SKILLS_DIR"
else
  EFFECTIVE_CODEX_HOME="$RUNTIME_CODEX_HOME"
  EFFECTIVE_SKILLS_DIR="$EFFECTIVE_CODEX_HOME/skills"
  mkdir -p "$EFFECTIVE_CODEX_HOME"
  if [ -d "$CODEX_HOME" ]; then
    cp -R "$CODEX_HOME/." "$EFFECTIVE_CODEX_HOME/" 2>/dev/null || true
  fi
  mkdir -p "$EFFECTIVE_SKILLS_DIR"
  if [ -d "$GLOBAL_SKILLS_DIR" ]; then
    cp -R "$GLOBAL_SKILLS_DIR/." "$EFFECTIVE_SKILLS_DIR/" 2>/dev/null || true
  fi
  CODEX_HOME="$EFFECTIVE_CODEX_HOME"
  export CODEX_HOME
  echo "warning: '$GLOBAL_SKILLS_DIR' is not writable; using CODEX_HOME='$CODEX_HOME' for writable skills." >&2
fi

if [ -d "$BUNDLED_SKILLS_DIR" ]; then
  for bundled_skill_path in "$BUNDLED_SKILLS_DIR"/*; do
    [ -d "$bundled_skill_path" ] || continue
    skill_name=$(basename "$bundled_skill_path")
    installed_skill_path="$EFFECTIVE_SKILLS_DIR/$skill_name"
    if [ ! -e "$installed_skill_path" ]; then
      if ! cp -R "$bundled_skill_path" "$installed_skill_path" 2>/dev/null; then
        echo "warning: could not install bundled skill '$skill_name' into '$EFFECTIVE_SKILLS_DIR'." >&2
      fi
    fi
  done
fi

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  : "${PROMPTED_BY_NAME:=$(git config --local --get user.name || git config --get user.name || true)}"
  : "${PROMPTED_BY_EMAIL:=$(git config --local --get user.email || git config --get user.email || true)}"
  export PROMPTED_BY_NAME PROMPTED_BY_EMAIL

  : "${CODING_AGENT_NAME:=$AGENT_AUTHOR_NAME}"
  : "${CODING_AGENT_MODEL:=GPT-5}"
  : "${CODING_AGENT_MODEL_VERSION:=gpt-5}"
  : "${CODING_AGENT_MODEL_PARAMS:=approval-mode=$CODEX_APPROVAL_MODE;sandbox=$CODEX_SANDBOX_MODE}"
  export CODING_AGENT_NAME CODING_AGENT_MODEL CODING_AGENT_MODEL_VERSION CODING_AGENT_MODEL_PARAMS
fi

git config --global user.name "$AGENT_AUTHOR_NAME"
git config --global user.email "$AGENT_AUTHOR_EMAIL"

if [ "$#" -eq 0 ]; then
  set -- codex
fi

if [ "$1" = "codex" ]; then
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
    set -- "$@" --ask-for-approval "$CODEX_APPROVAL_MODE"
  fi
  if [ "$has_sandbox_mode" -eq 0 ]; then
    set -- "$@" --sandbox "$CODEX_SANDBOX_MODE"
  fi
fi

exec "$@"
