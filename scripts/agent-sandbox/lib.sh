#!/bin/sh

set -eu

SEEN_VARS=""
RUN_CMD=""

append_arg() {
  escaped=$(printf "%s" "$1" | sed "s/'/'\\\\''/g")
  RUN_CMD="$RUN_CMD '$escaped'"
}

add_seen_var() {
  candidate=${1:-}
  if [ -z "$candidate" ]; then
    return
  fi
  case " $SEEN_VARS " in
    *" $candidate "*) ;;
    *) SEEN_VARS="$SEEN_VARS $candidate" ;;
  esac
}

agent_sandbox_main() {
  workdir=${WORKDIR:-$PWD}

  if [ "$#" -gt 0 ] && [ -d "$1" ]; then
    workdir=$1
    shift
  fi

  runtime=${OCI_RUNTIME:-docker}
  if ! command -v "$runtime" >/dev/null 2>&1; then
    echo "error: runtime '$runtime' not found on PATH." >&2
    echo "check \$OCI_RUNTIME environment" >&2
    exit 1
  fi

  script_path=${AGENT_SCRIPT_PATH:-}
  if [ -z "$script_path" ]; then
    echo "error: AGENT_SCRIPT_PATH must be set by launcher." >&2
    exit 1
  fi

  build_context=${AGENT_CONTEXT_DIR:-$script_path/agent-sandbox}
  image=${AGENT_SANDBOX_IMAGE:-}
  if [ -z "$image" ]; then
    echo "error: AGENT_SANDBOX_IMAGE must be set" >&2
    exit 1
  fi

  agent_npm_package=${AGENT_NPM_PACKAGE:-}
  if [ -z "$agent_npm_package" ]; then
    echo "error: AGENT_NPM_PACKAGE must be set" >&2
    exit 1
  fi

  agent_home=${AGENT_HOME_DIR:-/home/codex/.codex}
  agent_user=${AGENT_USER:-codex}

  prompted_by_name=${PROMPTED_BY_NAME:-$(git -C "$workdir" config --get user.name || true)}
  prompted_by_email=${PROMPTED_BY_EMAIL:-$(git -C "$workdir" config --get user.email || true)}

  agent_name=${AGENT_NAME:-${AGENT_AUTHOR_NAME:-Codex}}
  model=${AGENT_MODEL:-unknown}
  model_version=${AGENT_MODEL_VERSION:-$model}
  model_params=${AGENT_MODEL_PARAMS:-approval-mode=${AGENT_APPROVAL_MODE:-never};sandbox=${AGENT_SANDBOX_MODE:-danger-full-access}}

  "$runtime" build \
    -f "$build_context/Dockerfile" \
    -t "$image" \
    --build-arg "AGENT_NPM_PACKAGE=$agent_npm_package" \
    --build-arg "AGENT_HOME_DIR=$agent_home" \
    --build-arg "AGENT_USER=$agent_user" \
    "$build_context"

  RUN_CMD=""
  append_arg "$runtime"
  append_arg run
  append_arg --rm
  append_arg -it
  append_arg -v
  append_arg "$workdir:/workspace"
  append_arg -w
  append_arg /workspace
  append_arg -e
  append_arg "PROMPTED_BY_NAME=$prompted_by_name"
  append_arg -e
  append_arg "PROMPTED_BY_EMAIL=$prompted_by_email"
  append_arg -e
  append_arg "AGENT_KIND=${AGENT_KIND:-unknown}"
  append_arg -e
  append_arg "AGENT_NAME=$agent_name"
  append_arg -e
  append_arg "AGENT_MODEL=$model"
  append_arg -e
  append_arg "AGENT_MODEL_VERSION=$model_version"
  append_arg -e
  append_arg "AGENT_MODEL_PARAMS=$model_params"
  append_arg -e
  append_arg "AGENT_AUTHOR_NAME=${AGENT_AUTHOR_NAME:-Codex}"
  append_arg -e
  append_arg "AGENT_AUTHOR_EMAIL=${AGENT_AUTHOR_EMAIL:-codex@openai.com}"
  append_arg -e
  append_arg "AGENT_APPROVAL_MODE=${AGENT_APPROVAL_MODE:-never}"
  append_arg -e
  append_arg "AGENT_SANDBOX_MODE=${AGENT_SANDBOX_MODE:-danger-full-access}"
  append_arg -e
  append_arg "AGENT_DEFAULT_CMD=${AGENT_DEFAULT_CMD:-codex}"
  append_arg -e
  append_arg "AGENT_HOME_DIR=$agent_home"

  SEEN_VARS=""
  for var in ${AGENT_FORWARD_ENV_VARS:-}; do
    add_seen_var "$var"
  done

  for prefix in ${AGENT_FORWARD_ENV_PREFIXES:-}; do
    for env_name in $(env | sed 's/=.*//'); do
      case "$env_name" in
        "$prefix"*) add_seen_var "$env_name" ;;
      esac
    done
  done

  for var in $SEEN_VARS; do
    eval "var_value=\${$var-}"
    if [ -n "${var_value:-}" ]; then
      append_arg -e
      append_arg "$var"
    fi
  done

  if [ -n "${AGENT_SKILLS_DIR:-}" ] && [ -d "$AGENT_SKILLS_DIR" ]; then
    append_arg -v
    append_arg "$AGENT_SKILLS_DIR:$agent_home/skills:ro"
  fi

  if [ -n "${AGENT_AGENTS_FILE:-}" ] && [ -f "$AGENT_AGENTS_FILE" ]; then
    append_arg -v
    append_arg "$AGENT_AGENTS_FILE:$agent_home/AGENTS.md:ro"
  fi

  append_arg "$image"
  if [ "$#" -gt 0 ]; then
    for arg in "$@"; do
      append_arg "$arg"
    done
  else
    append_arg "${AGENT_DEFAULT_CMD:-codex}"
  fi

  # RUN_CMD is built from single-quoted args in append_arg.
  # shellcheck disable=SC2086
  eval "set -- $RUN_CMD"
  exec "$@"
}
