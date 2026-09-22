bits 16
org 0x0000

start:
    cli

    mov ax, cs
    mov ds, ax
    mov es, ax

    mov si, message
    call print_string

    sti

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

message:
    db 13, 10
    db "--------------------------------", 13, 10
    db "          KERNEL 1.2B", 13, 10
    db "--------------------------------", 13, 10
    db 13, 10
    db "The kernel was loaded from", 13, 10
    db "the virtual disk successfully.", 13, 10
    db 13, 10
    db "KERNEL OK.", 13, 10
    db 0
