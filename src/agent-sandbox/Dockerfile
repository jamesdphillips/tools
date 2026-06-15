FROM alpine:latest

ARG AGENT_NPM_PACKAGE
ARG AGENT_HOME_DIR=/home/codex/.codex
ARG AGENT_USER=codex

RUN test -n "$AGENT_NPM_PACKAGE" \
    && apk add --no-cache bash ca-certificates git nodejs npm ripgrep tini \
    && npm install --global "$AGENT_NPM_PACKAGE" \
    && adduser -D -h "/home/$AGENT_USER" "$AGENT_USER"

WORKDIR /workspace

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY agent-commit.sh /usr/local/bin/agent-commit.sh
COPY AGENTS.override.md "$AGENT_HOME_DIR/AGENTS.override.md"
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/agent-commit.sh \
    && mkdir -p "$AGENT_HOME_DIR" \
    && chown -R "$AGENT_USER:$AGENT_USER" "/home/$AGENT_USER" /workspace

USER $AGENT_USER

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["codex"]
