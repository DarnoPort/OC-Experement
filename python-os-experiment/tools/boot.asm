bits 16
org 0x7C3E

%ifndef KERNEL_SECTORS
%define KERNEL_SECTORS 1
%endif

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov ax, 0x9000
    mov ss, ax
    xor sp, sp

    mov [boot_drive], dl

    mov si, message
    call print_string

    mov ah, 0x41
    mov bx, 0x55AA
    mov dl, [boot_drive]
    int 0x13
    jc disk_extensions_error

    cmp bx, 0xAA55
    jne disk_extensions_error

    test cx, 0x0001
    jz disk_extensions_error

    mov word [dap.sectors], KERNEL_SECTORS

    mov si, dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc disk_read_error

    mov si, kernel_loaded_message
    call print_string

    sti

    jmp 0x1000:0x0000

disk_extensions_error:
    mov si, extensions_error_message
    call print_string
    jmp halt

disk_read_error:
    mov si, read_error_message
    call print_string

halt:
    cli
.hang:
    hlt
    jmp .hang

print_string:
.next:
    lodsb

    test al, al
    jz .done

    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10

    jmp .next

.done:
    ret

boot_drive:
    db 0

dap:
    db 0x10
    db 0x00
.sectors:
    dw KERNEL_SECTORS
.offset:
    dw 0x0000
.segment:
    dw 0x1000
    dq 1

message:
    db 13, 10
    db "================================", 13, 10
    db "       PYTHON OS 1.2B", 13, 10
    db "================================", 13, 10
    db 13, 10
    db "Bootloader is running.", 13, 10
    db "Loading kernel from disk...", 13, 10
    db 0

kernel_loaded_message:
    db "Kernel loaded successfully.", 13, 10
    db 0

extensions_error_message:
    db "ERROR: BIOS does not support", 13, 10
    db "required disk extensions.", 13, 10
    db 0

read_error_message:
    db "ERROR: Could not read kernel", 13, 10
    db "from the virtual disk.", 13, 10
    db 0

times 448 - ($ - $$) db 0
