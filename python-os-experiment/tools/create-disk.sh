#!/usr/bin/env bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DISK_IMAGE="$BUILD_DIR/disk.img"

BOOT_SOURCE="$PROJECT_ROOT/tools/boot.asm"
BOOT_BINARY="$BUILD_DIR/boot.bin"

KERNEL_SOURCE="$PROJECT_ROOT/tools/kernel.asm"
KERNEL_BINARY="$BUILD_DIR/kernel.bin"

DISK_SIZE_MB=64
RESERVED_SECTORS=4096
BOOT_CODE_OFFSET=62
MAX_BOOT_CODE_SIZE=448
MAX_KERNEL_SECTORS=$((RESERVED_SECTORS - 1))

echo "=== Python OS disk builder ==="

command -v mkfs.fat >/dev/null 2>&1 || {
    echo "Error: mkfs.fat not found."
    echo "Install it with:"
    echo "  sudo apt install dosfstools"
    exit 1
}

command -v nasm >/dev/null 2>&1 || {
    echo "Error: nasm not found."
    echo "Install it with:"
    echo "  sudo apt install nasm"
    exit 1
}

mkdir -p "$BUILD_DIR"

echo
echo "[1/6] Creating empty disk image..."

rm -f "$DISK_IMAGE" "$BOOT_BINARY" "$KERNEL_BINARY"

dd if=/dev/zero \
   of="$DISK_IMAGE" \
   bs=1M \
   count="$DISK_SIZE_MB" \
   status=progress

echo
echo "[2/6] Creating FAT16 filesystem..."

mkfs.fat \
    -F 16 \
    -R "$RESERVED_SECTORS" \
    --mbr=no \
    -n PYOS \
    "$DISK_IMAGE"

echo
echo "[3/6] Building kernel..."

nasm \
    -f bin \
    "$KERNEL_SOURCE" \
    -o "$KERNEL_BINARY"

KERNEL_SIZE=$(stat -c%s "$KERNEL_BINARY")
KERNEL_SECTORS=$(( (KERNEL_SIZE + 511) / 512 ))

if [ "$KERNEL_SECTORS" -gt "$MAX_KERNEL_SECTORS" ]; then
    echo "Error: kernel is too large for the reserved area."
    echo "Kernel sectors: $KERNEL_SECTORS"
    echo "Maximum sectors: $MAX_KERNEL_SECTORS"
    exit 1
fi

echo "Kernel size: $KERNEL_SIZE bytes"
echo "Kernel sectors: $KERNEL_SECTORS"

echo
echo "[4/6] Building bootloader..."

nasm \
    -f bin \
    -dKERNEL_SECTORS="$KERNEL_SECTORS" \
    "$BOOT_SOURCE" \
    -o "$BOOT_BINARY"

BOOT_SIZE=$(stat -c%s "$BOOT_BINARY")

if [ "$BOOT_SIZE" -gt "$MAX_BOOT_CODE_SIZE" ]; then
    echo "Error: bootloader is too large."
    echo "Size: $BOOT_SIZE bytes"
    echo "Maximum: $MAX_BOOT_CODE_SIZE bytes"
    exit 1
fi

echo "Bootloader size: $BOOT_SIZE bytes"

echo
echo "[5/6] Installing bootloader..."

dd if="$BOOT_BINARY" \
   of="$DISK_IMAGE" \
   bs=1 \
   seek="$BOOT_CODE_OFFSET" \
   conv=notrunc \
   status=none

echo
echo "[6/6] Installing kernel..."

dd if="$KERNEL_BINARY" \
   of="$DISK_IMAGE" \
   bs=512 \
   seek=1 \
   conv=notrunc \
   status=none

echo
echo "Disk created successfully."
echo
echo "Image:             $DISK_IMAGE"
echo "Size:              ${DISK_SIZE_MB} MiB"
echo "Filesystem:        FAT16"
echo "Reserved sectors:  $RESERVED_SECTORS"
echo "Bootloader:        sector 0"
echo "Kernel:            sector 1-$KERNEL_SECTORS"
echo "Application area:  starts after reserved sectors"
