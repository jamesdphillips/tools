#!/bin/sh
set -eu

tmp=$(mktemp "${TMPDIR:-/tmp}/edit.XXXXXX")
trap 'rm -f "$tmp"' EXIT HUP INT TERM

editor=${VISUAL:-${EDITOR:-ed}}

# Optional: seed temp file from stdin if stdin is not the terminal
if [ ! -t 0 ]; then
  cat > "$tmp"
fi

# Run editor attached to the real terminal, not the pipeline
"$editor" "$tmp" </dev/tty >/dev/tty 2>/dev/tty

# Emit edited result to stdout
cat "$tmp"

