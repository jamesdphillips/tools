FROM alpine:3.21

RUN apk add --no-cache bash ca-certificates git nodejs npm tini \
    && npm install --global @openai/codex \
    && adduser -D -h /home/codex codex

WORKDIR /workspace

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && mkdir -p /home/codex/.codex \
    && chown -R codex:codex /home/codex /workspace

USER codex

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["codex"]
