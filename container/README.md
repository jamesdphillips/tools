# Container Workflow

This container is a local agent sandbox:

- Alpine base
- Codex CLI installed
- Repo hooks/template auto-configured on startup
- Agent author defaults set to `Codex <codex@users.noreply.local>`
- Git config is written to container-global config, not host repo config

## Run

```sh
container/run.sh
```

Use a different runtime:

```sh
OCI_RUNTIME=podman container/run.sh
```

Run a specific command:

```sh
container/run.sh codex --help
```

## Auth

If `OPENAI_API_KEY` is set on host, `container/run.sh` forwards it.

## Optional Skills Mount

If `$HOME/.codex/skills` exists, it is mounted read-only into the container.
