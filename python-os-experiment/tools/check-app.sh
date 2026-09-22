#!/usr/bin/env bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK_IMAGE="$PROJECT_ROOT/build/disk.img"

if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 <original-python-file>"
    exit 1
fi

SOURCE_FILE="$1"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: source file does not exist:"
    echo "  $SOURCE_FILE"
    exit 1
fi

if [ ! -f "$DISK_IMAGE" ]; then
    echo "Error: disk image does not exist."
    exit 1
fi

if ! mdir -i "$DISK_IMAGE" "::/APP.PY" >/dev/null 2>&1; then
    echo "Error: /APP.PY is not installed."
    exit 1
fi

TEMP_FILE="$(mktemp)"

cleanup() {
    rm -f "$TEMP_FILE"
}

trap cleanup EXIT

mcopy -i "$DISK_IMAGE" "::/APP.PY" "$TEMP_FILE"

if cmp -s "$SOURCE_FILE" "$TEMP_FILE"; then
    echo "Application verification successful."
    echo "Source file and /APP.PY are identical."
else
    echo "ERROR: files are different."
    exit 1
fi