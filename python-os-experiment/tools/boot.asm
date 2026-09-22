bits 16
org 0x7C3E

start:
    cli

    xor ax, ax
    mov ds, ax
    mov es, ax

    mov si, message

.print:
    lodsb
    test al, al
    jz .done

    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10

    jmp .print

.done:
    sti

.hang:
    hlt
    jmp .hang

message:
    db 13, 10
    db "================================", 13, 10
    db "       PYTHON OS 1.2A", 13, 10
    db "================================", 13, 10
    db 13, 10
    db "Our bootloader is running!", 13, 10
    db "BIOS successfully passed control", 13, 10
    db "to our code from the virtual disk.", 13, 10
    db 13, 10
    db "BOOT OK.", 13, 10
    db 0

times 448 - ($ - $$) db 0