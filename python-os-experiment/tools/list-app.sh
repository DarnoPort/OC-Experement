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

echo "=== Virtual disk ==="
echo

mdir -i "$DISK_IMAGE" "::/"