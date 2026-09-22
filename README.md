# OC-Experement

Experimental operating system platform whose long-term goal is to run external Python applications inside its own OS.

## Current phase

### Phase 1.1
- FAT16 virtual disk
- Single application: /APP.PY
- install-app
- remove-app
- application verification

### Phase 1.2B
- QEMU boots the virtual disk
- BIOS enters the custom boot sector
- bootloader checks BIOS INT 13h extensions
- bootloader loads the kernel from reserved sector 1
- kernel starts in real mode and prints a confirmation message

## Project layout

- \`python-os-experiment/apps/\` — external Python applications
- \`python-os-experiment/tools/boot.asm\` — first-stage bootloader
- \`python-os-experiment/tools/kernel.asm\` — experimental kernel
- \`python-os-experiment/tools/*.sh\` — disk/application tools
- \`python-os-experiment/build/\` — generated files, not source

## Basic workflow

From \`python-os-experiment/\`:

\`\`\`bash
make create-disk
make install-app APP=apps/test.py
make check-app APP=apps/test.py
make run
\`\`\`

The current kernel does not execute Python yet. MicroPython will be integrated only after the disk -> bootloader -> kernel chain is working reliably.
