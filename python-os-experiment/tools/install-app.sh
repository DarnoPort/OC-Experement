#!/usr/bin/env bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DISK_IMAGE="$PROJECT_ROOT/build/disk.img"

if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 <python-file>"
    exit 1
fi

SOURCE_FILE="$1"

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: file does not exist:"
    echo "  $SOURCE_FILE"
    exit 1
fi

case "$SOURCE_FILE" in
    *.py|*.PY)
        ;;
    *)
        echo "Error: application must have .py extension."
        exit 1
        ;;
esac

if [ ! -f "$DISK_IMAGE" ]; then
    echo "Error: disk image does not exist."
    echo "Create it first:"
    echo "  make create-disk"
    exit 1
fi

if mdir -i "$DISK_IMAGE" "::/APP.PY" >/dev/null 2>&1; then
    echo "Error: an application is already installed."
    echo "Remove it first:"
    echo "  make remove-app"
    exit 1
fi

echo "Installing application:"
echo "  $SOURCE_FILE"
echo
echo "Destination:"
echo "  /APP.PY"
echo

mcopy -i "$DISK_IMAGE" "$SOURCE_FILE" "::/APP.PY"

echo "Application installed successfully."