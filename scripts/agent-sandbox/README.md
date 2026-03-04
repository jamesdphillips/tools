# Agent Sandbox

Shared container sandbox for coding agents.

## Launchers

- `scripts/codex-sandbox.sh`
- `scripts/claude-sandbox.sh`

## Runtime

Uses `docker` by default. Override with `OCI_RUNTIME`.

## Commands

- `scripts/codex-sandbox.sh` defaults to running `codex`.
- `scripts/claude-sandbox.sh` defaults to running `claude`.

If the first argument is a directory, it is mounted as `/workspace`.
Remaining arguments are passed to the in-container command.

## Config

- `CODEX_SANDBOX_IMAGE` / `CLAUDE_SANDBOX_IMAGE`: image tag override.
- `CLAUDE_NPM_PACKAGE`: npm package override for Claude CLI install.

## Auth Forwarding

Codex launcher forwards:
- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `OPENAI_ORG_ID`
- `OPENAI_PROJECT_ID`

Claude launcher forwards:
- `ANTHROPIC_API_KEY`
- `ANTHROPIC_BASE_URL`
- all vars prefixed with `CLAUDE_`
- OpenAI vars above

## Optional Mounts

If present, these host paths are mounted read-only to `/home/codex/.codex`:
- skills dir as `skills`
- AGENTS file as `AGENTS.md`
