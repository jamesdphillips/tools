#!/bin/sh

set -eu

git config core.hooksPath .githooks
git config commit.template .gitmessage.codex

echo "Configured:"
echo "  core.hooksPath=.githooks"
echo "  commit.template=.gitmessage.codex"
