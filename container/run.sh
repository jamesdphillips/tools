#!/usr/bin/env bash

set -euo pipefail

workdir="${1:-$PWD}"
script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_context="$script_path"
image="${CODEX_SANDBOX_IMAGE:-codex-sandbox:latest}"

# Use configured OCI runtime
runtime="${OCI_RUNTIME:-docker}"
if ! command -v "$runtime" >/dev/null 2>&1; then
  echo "error: runtime '$runtime' not found on PATH." >&2
  echo "check \$OCI_RUNTIME environment" >&2
  exit 1
fi

# 
prompted_by_name="${PROMPTED_BY_NAME:-$(git -C "$workdir" config --get user.name || true)}"
prompted_by_email="${PROMPTED_BY_EMAIL:-$(git -C "$workdir" config --get user.email || true)}"

#
# TODO:
#
# is this the correct approach? it feels like this should be done at runtime?
#
agent_name="${CODING_AGENT_NAME:-Codex}"
model="${CODING_AGENT_MODEL:-GPT-5}"
model_version="${CODING_AGENT_MODEL_VERSION:-gpt-5}"
model_params="${CODING_AGENT_MODEL_PARAMS:-approval-mode=${CODEX_APPROVAL_MODE:-manual};sandbox=${CODEX_SANDBOX_MODE:-workspace-write}}"

# Build
"$runtime" build -f "$build_context/Dockerfile" -t "$image" "$build_context"

# Run codex
run_cmd=(
  "$runtime" run --rm -it
  -v "$workdir:/workspace"
  -w /workspace
  -e "PROMPTED_BY_NAME=$prompted_by_name"
  -e "PROMPTED_BY_EMAIL=$prompted_by_email"
  -e "CODING_AGENT_NAME=$agent_name"
  -e "CODING_AGENT_MODEL=$model"
  -e "CODING_AGENT_MODEL_VERSION=$model_version"
  -e "CODING_AGENT_MODEL_PARAMS=$model_params"
)

for var in OPENAI_API_KEY OPENAI_BASE_URL OPENAI_ORG_ID OPENAI_PROJECT_ID; do
  if [[ -n "${!var:-}" ]]; then
    run_cmd+=(-e "$var")
  fi
done

skills_dir="${CODEX_SKILLS_DIR:-$HOME/.codex/skills}"
if [[ -d "$skills_dir" ]]; then
  run_cmd+=(-v "$skills_dir:/home/codex/.codex/skills:ro")
fi

run_cmd+=("$image")
if [[ "$#" -gt 0 ]]; then
  run_cmd+=("$@")
else
  run_cmd+=(codex)
fi

exec "${run_cmd[@]}"
