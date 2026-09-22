#!/usr/bin/env bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK_IMAGE="$PROJECT_ROOT/build/disk.img"

if [ ! -f "$DISK_IMAGE" ]; then
    echo "Error: disk image does not exist."
    echo "Create it first:"
    echo "  make create-disk"
    exit 1
fi

if ! mdir -i "$DISK_IMAGE" "::/APP.PY" >/dev/null 2>&1; then
    echo "No application is currently installed."
    exit 0
fi

echo "Removing /APP.PY..."

mdel -i "$DISK_IMAGE" "::/APP.PY"

echo "Application removed successfully."