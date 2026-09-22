# OC-Experement

Experimental operating system platform whose long-term goal is to run external Python applications inside its own OS.

## Current status

### Phase 1.1 — virtual application disk
- FAT16 virtual disk
- Single application: /APP.PY
- install-app
- remove-app
- application verification

### Phase 1.2 — real QEMU boot
- BIOS boots the virtual disk
- custom boot sector runs
- bootloader uses BIOS INT 13h extensions
- kernel is loaded from the reserved disk area
- kernel starts in 16-bit real mode

### Phase 1.3 — application discovery and loading
- kernel reads the FAT16 BIOS Parameter Block
- kernel locates /APP.PY in the FAT16 root directory
- kernel follows the FAT16 cluster chain
- kernel loads APP.PY into RAM
- kernel shows a small preview of the loaded file
- Python is not executed yet

## Project layout

- `python-os-experiment/apps/` — external Python applications
- `python-os-experiment/tools/boot.asm` — first-stage bootloader
- `python-os-experiment/tools/kernel.asm` — experimental kernel
- `python-os-experiment/tools/*.sh` — disk/application tools
- `python-os-experiment/build/` — generated files, ignored by Git

## Basic workflow

From `python-os-experiment/`:

```bash
git pull
make clean
make create-disk
make install-app APP=apps/test.py
make check-app APP=apps/test.py
make run
```

The current kernel loads the external APP.PY file but does not execute Python yet. MicroPython will be integrated after the disk, filesystem and application-loading path is stable.
