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

command -v qemu-system-i386 >/dev/null 2>&1 || {
    echo "Error: qemu-system-i386 not found."
    echo "Install it with:"
    echo "  sudo apt install qemu-system-x86"
    exit 1
}

qemu-system-i386 \
    -machine pc \
    -m 32M \
    -drive file="$DISK_IMAGE",format=raw,if=ide \
    -boot c