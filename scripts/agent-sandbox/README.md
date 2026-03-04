# Agent Sandbox

Shared container sandbox for coding agents.

## Scripts

- `scripts/codex-sandbox.sh`: run Codex CLI in the sandbox.
- `scripts/claude-sandbox.sh`: run Claude CLI in the sandbox.

## Runtime

Uses `docker` by default. Override with `OCI_RUNTIME`.

## Auth Forwarding

Codex wrapper forwards:
- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `OPENAI_ORG_ID`
- `OPENAI_PROJECT_ID`

Claude wrapper forwards Claude/Anthropic and OpenAI vars.

## Optional Mounts

If present, these host files are mounted read-only:
- skills dir -> `/home/codex/.codex/skills`
- AGENTS file -> `/home/codex/.codex/AGENTS.md`

## Workdir

If the first argument is a directory, it is mounted as `/workspace`.
Remaining arguments are passed to the agent command.
