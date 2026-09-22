bits 16
org 0x0000

APP_LOAD_SEGMENT       equ 0x2000
BPB_BUFFER_SEGMENT     equ 0x7000
SECTOR_BUFFER_SEGMENT  equ 0x8000

APP_MAX_SIZE           equ 0x00060000
APP_PREVIEW_SIZE       equ 64

start:
    cli
    cld

    mov ax, cs
    mov ds, ax
    mov es, ax

    mov ax, 0x9000
    mov ss, ax
    xor sp, sp

    mov si, startup_message
    call print_string

    call get_boot_drive

    mov si, filesystem_message
    call print_string

    call load_boot_sector
    jc disk_error

    call parse_bpb
    jc filesystem_error

    call find_application
    jc application_not_found

    mov si, application_found_message
    call print_string

    mov eax, [app_size]
    mov si, application_size_message
    call print_string
    call print_hex32
    mov si, newline
    call print_string

    cmp eax, APP_MAX_SIZE
    ja application_too_large

    call load_application
    jc disk_error

    mov si, application_loaded_message
    call print_string

    mov si, application_preview_message
    call print_string

    call print_application_preview

    mov si, application_complete_message
    call print_string

    sti

.hang:
    hlt
    jmp .hang

get_boot_drive:
    push ds
    xor ax, ax
    mov ds, ax
    mov dl, [0x0600]
    pop ds
    mov [boot_drive], dl
    ret

load_boot_sector:
    mov ax, BPB_BUFFER_SEGMENT
    mov es, ax
    xor bx, bx
    xor eax, eax
    call read_sector
    ret

parse_bpb:
    movzx eax, word [es:0x0B]
    mov [bytes_per_sector], eax

    cmp eax, 512
    jne .invalid

    movzx eax, byte [es:0x0D]
    test eax, eax
    jz .invalid
    mov [sectors_per_cluster], eax

    movzx eax, word [es:0x0E]
    test eax, eax
    jz .invalid
    mov [reserved_sectors], eax

    movzx eax, byte [es:0x10]
    test eax, eax
    jz .invalid
    mov [number_of_fats], eax

    movzx eax, word [es:0x11]
    test eax, eax
    jz .invalid
    mov [root_entries], eax

    movzx eax, word [es:0x16]
    test eax, eax
    jz .invalid
    mov [sectors_per_fat], eax

    mov eax, [reserved_sectors]
    mov [fat_start], eax

    mov eax, [number_of_fats]
    mov ebx, [sectors_per_fat]
    imul eax, ebx
    add eax, [fat_start]
    mov [root_start], eax

    mov eax, [root_entries]
    mov ebx, 32
    imul eax, ebx
    add eax, 511

    mov ebx, [bytes_per_sector]
    xor edx, edx
    div ebx
    mov [root_dir_sectors], eax

    mov eax, [root_start]
    add eax, [root_dir_sectors]
    mov [data_start], eax

    clc
    ret

.invalid:
    stc
    ret

find_application:
    xor eax, eax
    mov [root_sector_index], eax

.next_sector:
    mov eax, [root_sector_index]
    cmp eax, [root_dir_sectors]
    jae .not_found

    mov eax, [root_start]
    add eax, [root_sector_index]

    mov ax, SECTOR_BUFFER_SEGMENT
    mov es, ax
    xor bx, bx

    mov eax, [root_start]
    add eax, [root_sector_index]
    call read_sector
    jc .disk_error

    xor di, di

.next_entry:
    cmp byte [es:di], 0x00
    je .not_found

    cmp byte [es:di], 0xE5
    je .skip_entry

    push di
    mov si, app_name
    mov cx, 11
    repe cmpsb
    pop di
    je .found

.skip_entry:
    add di, 32
    cmp di, 512
    jb .next_entry

    inc dword [root_sector_index]
    jmp .next_sector

.found:
    mov ax, [es:di + 26]
    mov [app_cluster], ax

    mov eax, [es:di + 28]
    mov [app_size], eax

    mov eax, [app_size]
    test eax, eax
    jz .accept

    movzx eax, word [app_cluster]
    cmp eax, 2
    jb .invalid

.accept:
    clc
    ret

.invalid:
    stc
    ret

.not_found:
    stc
    ret

.disk_error:
    stc
    ret

load_application:
    mov eax, [app_size]
    test eax, eax
    jz .success

    mov eax, APP_LOAD_SEGMENT
    mov [load_segment], eax

    mov eax, [app_size]
    mov [bytes_remaining], eax

    movzx eax, word [app_cluster]
    mov [current_cluster], eax

.cluster_loop:
    mov eax, [bytes_remaining]
    test eax, eax
    jz .success

    mov eax, [current_cluster]
    cmp eax, 2
    jb .failure
    cmp eax, 0xFFF7
    jae .failure

    xor eax, eax
    mov [cluster_sector_index], eax

.sector_loop:
    mov eax, [bytes_remaining]
    test eax, eax
    jz .success

    mov eax, [cluster_sector_index]
    cmp eax, [sectors_per_cluster]
    jae .next_cluster

    mov eax, [current_cluster]
    sub eax, 2

    mov ebx, [sectors_per_cluster]
    imul eax, ebx

    add eax, [data_start]
    add eax, [cluster_sector_index]

    xor bx, bx
    mov ax, word [load_segment]
    mov es, ax

    call read_sector
    jc .failure

    add dword [load_segment], 0x20

    mov eax, [bytes_remaining]
    cmp eax, 512
    jbe .last_sector
    sub eax, 512
    mov [bytes_remaining], eax
    jmp .continue_sector

.last_sector:
    mov dword [bytes_remaining], 0

.continue_sector:
    inc dword [cluster_sector_index]
    jmp .sector_loop

.next_cluster:
    movzx eax, word [current_cluster]
    call get_fat_entry
    jc .failure

    movzx eax, ax
    cmp eax, 0xFFF8
    jae .failure

    mov [current_cluster], eax
    jmp .cluster_loop

.success:
    clc
    ret

.failure:
    stc
    ret

get_fat_entry:
    movzx eax, ax
    shl eax, 1

    mov ebx, eax
    shr eax, 9
    mov [fat_sector_index], eax

    and ebx, 0x01FF
    mov [fat_offset], bx

    mov eax, [fat_start]
    add eax, [fat_sector_index]

    mov ax, SECTOR_BUFFER_SEGMENT
    mov es, ax
    xor bx, bx

    mov eax, [fat_start]
    add eax, [fat_sector_index]
    call read_sector
    jc .failure

    mov bx, [fat_offset]
    mov ax, [es:bx]

    clc
    ret

.failure:
    stc
    ret

print_application_preview:
    mov eax, [app_size]
    cmp eax, APP_PREVIEW_SIZE
    jae .count_ready

    mov cx, ax
    jmp .load_segment

.count_ready:
    mov cx, APP_PREVIEW_SIZE

.load_segment:
    mov ax, APP_LOAD_SEGMENT
    mov ds, ax
    xor si, si

.next_char:
    test cx, cx
    jz .done

    lodsb

    cmp al, 13
    je .print
    cmp al, 10
    je .print

    cmp al, 32
    jae .print

    mov al, '.'

.print:
    call print_char

    dec cx
    jmp .next_char

.done:
    push cs
    pop ds
    mov si, newline
    call print_string
    ret

print_string:
.next:
    lodsb

    test al, al
    jz .done

    call print_char
    jmp .next

.done:
    ret

print_char:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
    int 0x10
    ret

print_hex32:
    push ax
    mov ax, dx
    call print_hex16
    pop ax
    call print_hex16
    ret

print_hex16:
    push ax
    push bx
    push cx

    mov bx, ax
    mov cx, 4

.next_digit:
    rol bx, 4
    mov al, bl
    and al, 0x0F

    cmp al, 9
    jbe .numeric

    add al, 'A' - 10
    jmp .output

.numeric:
    add al, '0'

.output:
    call print_char
    loop .next_digit

    pop cx
    pop bx
    pop ax
    ret

read_sector:
    push eax
    push ebx
    push ecx
    push edx
    push si
    push di
    push es

    mov [dap.offset], bx

    mov ax, es
    mov [dap.segment], ax

    mov [dap.lba_low], eax
    mov dword [dap.lba_high], 0

    mov si, dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13

    pushf
    pop ax
    mov [read_flags], ax

    pop es
    pop di
    pop si
    pop edx
    pop ecx
    pop ebx
    pop eax

    mov ax, [read_flags]
    test ax, 1
    jnz .error

    clc
    ret

.error:
    stc
    ret

disk_error:
    mov si, disk_error_message
    call print_string
    jmp halt

filesystem_error:
    mov si, filesystem_error_message
    call print_string
    jmp halt

application_not_found:
    mov si, application_not_found_message
    call print_string
    jmp halt

application_too_large:
    mov si, application_too_large_message
    call print_string
    jmp halt

app_name:
    db "APP     PY"

boot_drive:
    db 0

read_flags:
    dw 0

bytes_per_sector:
    dd 0

sectors_per_cluster:
    dd 0

reserved_sectors:
    dd 0

number_of_fats:
    dd 0

root_entries:
    dd 0

sectors_per_fat:
    dd 0

fat_start:
    dd 0

root_start:
    dd 0

root_dir_sectors:
    dd 0

data_start:
    dd 0

root_sector_index:
    dd 0

app_cluster:
    dw 0

app_size:
    dd 0

current_cluster:
    dd 0

cluster_sector_index:
    dd 0

bytes_remaining:
    dd 0

load_segment:
    dd 0

fat_sector_index:
    dd 0

fat_offset:
    dw 0

dap:
    db 0x10
    db 0x00
.sectors:
    dw 1
.offset:
    dw 0
.segment:
    dw 0
.lba_low:
    dd 0
.lba_high:
    dd 0

startup_message:
    db 13, 10
    db "================================", 13, 10
    db "          KERNEL 1.3", 13, 10
    db "================================", 13, 10
    db 13, 10
    db "Kernel started.", 13, 10
    db 0

filesystem_message:
    db "Reading FAT16 filesystem...", 13, 10
    db 0

application_found_message:
    db "Application found: APP.PY", 13, 10
    db 0

application_size_message:
    db "Application size: 0x", 0

application_loaded_message:
    db "Application loaded into memory.", 13, 10
    db 0

application_preview_message:
    db "Application preview:", 13, 10
    db 0

application_complete_message:
    db "FILE LOAD OK.", 13, 10
    db 0

application_not_found_message:
    db "No application found: APP.PY", 13, 10
    db "System is waiting.", 13, 10
    db 0

application_too_large_message:
    db "ERROR: APP.PY is too large.", 13, 10
    db 0

disk_error_message:
    db "ERROR: Disk read failed.", 13, 10
    db 0

filesystem_error_message:
    db "ERROR: Unsupported FAT16 filesystem.", 13, 10
    db 0

newline:
    db 13, 10
    db 0
