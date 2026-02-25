#!/bin/sh

is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# create temp dir
TMPDIR=$(mktemp -d)

# mount tmpfs
if [[ "$(uname)" == "Darwin" ]]; then
  sudo mount_tmpfs -e $TMPDIR # macOS has some platform specific opts
else
  sudo mount -t tmpfs tmpfs $TMPDIR
fi

echo $TMPDIR

