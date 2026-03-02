FROM alpine:3.21

RUN apk add --no-cache bash ca-certificates git nodejs npm tini \
    && npm install --global @openai/codex \
    && adduser -D -h /home/codex codex

WORKDIR /workspace

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY agent-commit.sh /usr/local/bin/agent-commit.sh
COPY skills /usr/local/share/codex/skills
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/agent-commit.sh \
    && mkdir -p /home/codex/.codex \
    && chown -R codex:codex /home/codex /workspace

USER codex

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["codex"]
