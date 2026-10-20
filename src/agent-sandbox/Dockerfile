FROM alpine:latest

ARG AGENT_INSTALL_METHOD=npm
ARG AGENT_NPM_PACKAGE
ARG AGENT_HOME_DIR=/home/codex/.codex
ARG AGENT_USER=codex
ARG CODEX_RELEASE=latest
ENV HOME="/home/$AGENT_USER"
ENV PATH="$HOME/.local/bin:$PATH"

RUN apk add --no-cache bash ca-certificates git nodejs npm ripgrep tini wget \
    && adduser -D -h "/home/$AGENT_USER" "$AGENT_USER" \
    && mkdir -p "$AGENT_HOME_DIR" "$HOME/.local/bin" \
    && case "$AGENT_INSTALL_METHOD" in \
      npm) test -n "$AGENT_NPM_PACKAGE" && npm install --global "$AGENT_NPM_PACKAGE" ;; \
      standalone) wget -q -O /tmp/codex-install.sh https://chatgpt.com/codex/install.sh && CODEX_NON_INTERACTIVE=1 CODEX_INSTALL_DIR="$HOME/.local/bin" CODEX_HOME="$AGENT_HOME_DIR" CODEX_RELEASE="$CODEX_RELEASE" sh /tmp/codex-install.sh && "$HOME/.local/bin/codex" --version >/dev/null ;; \
      *) echo "Unsupported AGENT_INSTALL_METHOD: $AGENT_INSTALL_METHOD" >&2; exit 1 ;; \
    esac

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
