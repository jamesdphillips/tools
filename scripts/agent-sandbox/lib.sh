#!/usr/bin/env bash

set -euo pipefail

agent_sandbox_main() {
  local -a user_cmd
  local workdir="${WORKDIR:-$PWD}"

  if [[ $# -gt 0 && -d "$1" ]]; then
    workdir="$1"
    shift
  fi

  user_cmd=("$@")

  local runtime="${OCI_RUNTIME:-docker}"
  if ! command -v "$runtime" >/dev/null 2>&1; then
    echo "error: runtime '$runtime' not found on PATH." >&2
    echo "check \$OCI_RUNTIME environment" >&2
    exit 1
  fi

  local script_path
  script_path="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  local build_context="${AGENT_CONTEXT_DIR:-$script_path/agent-sandbox}"
  local image="${AGENT_SANDBOX_IMAGE:?AGENT_SANDBOX_IMAGE must be set}"
  local agent_home="${AGENT_HOME_DIR:-/home/codex/.codex}"
  local agent_user="${AGENT_USER:-codex}"

  local prompted_by_name prompted_by_email
  prompted_by_name="${PROMPTED_BY_NAME:-$(git -C "$workdir" config --get user.name || true)}"
  prompted_by_email="${PROMPTED_BY_EMAIL:-$(git -C "$workdir" config --get user.email || true)}"

  local agent_name model model_version model_params
  agent_name="${AGENT_NAME:-${AGENT_AUTHOR_NAME:-Codex}}"
  model="${AGENT_MODEL:-unknown}"
  model_version="${AGENT_MODEL_VERSION:-$model}"
  model_params="${AGENT_MODEL_PARAMS:-approval-mode=${AGENT_APPROVAL_MODE:-never};sandbox=${AGENT_SANDBOX_MODE:-danger-full-access}}"

  "$runtime" build \
    -f "$build_context/Dockerfile" \
    -t "$image" \
    --build-arg "AGENT_NPM_PACKAGE=${AGENT_NPM_PACKAGE:?AGENT_NPM_PACKAGE must be set}" \
    --build-arg "AGENT_HOME_DIR=$agent_home" \
    --build-arg "AGENT_USER=$agent_user" \
    "$build_context"

  local -a run_cmd
  run_cmd=(
    "$runtime" run --rm -it
    -v "$workdir:/workspace"
    -w /workspace
    -e "PROMPTED_BY_NAME=$prompted_by_name"
    -e "PROMPTED_BY_EMAIL=$prompted_by_email"
    -e "AGENT_KIND=${AGENT_KIND:-unknown}"
    -e "AGENT_NAME=$agent_name"
    -e "AGENT_MODEL=$model"
    -e "AGENT_MODEL_VERSION=$model_version"
    -e "AGENT_MODEL_PARAMS=$model_params"
    -e "AGENT_AUTHOR_NAME=${AGENT_AUTHOR_NAME:-Codex}"
    -e "AGENT_AUTHOR_EMAIL=${AGENT_AUTHOR_EMAIL:-codex@openai.com}"
    -e "AGENT_APPROVAL_MODE=${AGENT_APPROVAL_MODE:-never}"
    -e "AGENT_SANDBOX_MODE=${AGENT_SANDBOX_MODE:-danger-full-access}"
    -e "AGENT_DEFAULT_CMD=${AGENT_DEFAULT_CMD:-codex}"
    -e "AGENT_HOME_DIR=$agent_home"
  )

  local -A seen_vars=()
  local var
  for var in ${AGENT_FORWARD_ENV_VARS:-}; do
    seen_vars["$var"]=1
  done

  local prefix env_name
  for prefix in ${AGENT_FORWARD_ENV_PREFIXES:-}; do
    while IFS='=' read -r env_name _; do
      if [[ "$env_name" == "$prefix"* ]]; then
        seen_vars["$env_name"]=1
      fi
    done < <(env)
  done

  for var in "${!seen_vars[@]}"; do
    if [[ -n "${!var:-}" ]]; then
      run_cmd+=(-e "$var")
    fi
  done

  if [[ -n "${AGENT_SKILLS_DIR:-}" && -d "$AGENT_SKILLS_DIR" ]]; then
    run_cmd+=(-v "$AGENT_SKILLS_DIR:$agent_home/skills:ro")
  fi

  if [[ -n "${AGENT_AGENTS_FILE:-}" && -f "$AGENT_AGENTS_FILE" ]]; then
    run_cmd+=(-v "$AGENT_AGENTS_FILE:$agent_home/AGENTS.md:ro")
  fi

  run_cmd+=("$image")
  if [[ ${#user_cmd[@]} -gt 0 ]]; then
    run_cmd+=("${user_cmd[@]}")
  else
    run_cmd+=("${AGENT_DEFAULT_CMD:-codex}")
  fi

  exec "${run_cmd[@]}"
}
