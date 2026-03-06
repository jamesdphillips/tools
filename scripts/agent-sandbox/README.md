# Agent Sandbox

Shared container sandbox for coding agents.

## Launchers

- `scripts/codex-sandbox.sh`
- `scripts/claude-sandbox.sh`
- `scripts/opencode-sandbox.sh`

## Runtime

Uses `docker` by default. Override with `OCI_RUNTIME`.

## Commands

- `scripts/codex-sandbox.sh` defaults to running `codex`.
- `scripts/claude-sandbox.sh` defaults to running `claude`.
- `scripts/opencode-sandbox.sh` defaults to running `opencode`.

If the first argument is a directory, it is mounted as `/workspace`.
Remaining arguments are passed to the in-container command.

## Config

- `CODEX_SANDBOX_IMAGE` / `CLAUDE_SANDBOX_IMAGE` / `OPENCODE_SANDBOX_IMAGE`: image tag override.
- `CODEX_NPM_PACKAGE`: npm package override for Codex CLI install.
- `CLAUDE_NPM_PACKAGE`: npm package override for Claude CLI install.
- `OPENCODE_NPM_PACKAGE`: npm package override for OpenCode CLI install.
- `OPENCODE_SKILLS_DIR`: host skills dir override for OpenCode launcher.
- `OPENCODE_AGENTS_FILE`: host AGENTS file override for OpenCode launcher.

Launchers pass the selected npm package into the container as `AGENT_NPM_PACKAGE`.
On startup, the shared entrypoint attempts `npm install -g --no-fund "$AGENT_NPM_PACKAGE"`.
If that update fails, startup continues.

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

OpenCode launcher forwards:
- all vars prefixed with `OPENCODE_`

OpenCode defaults are optimized for Ollama/local usage and do not forward provider keys by default.

## Optional Mounts

If present, these host paths are mounted read-only to `/home/codex/.codex`:
- skills dir as `skills`
- AGENTS file as `AGENTS.md`
