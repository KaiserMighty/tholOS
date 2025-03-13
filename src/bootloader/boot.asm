org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A


; FAT12 header
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type   db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat         dw 9                    ; 9 sectors/fat
bdb_sectors_per_track       dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 42h, 11h, 37h, 05h   ; serial number
ebr_volume_label:           db 'THOLOS     '        ; 11 bytes
ebr_system_id:              db 'FAT12   '           ; 8 bytes

; Program
start:
    jmp main


; Print a string.
; Params:
;   - ds:si string pointer
puts:
    ; save registers
    push si
    push ax

.loop:
    lodsb                               ; get next char
    or al, al                           ; is char null
    jz .done

    mov ah, 0x0e                        ; bios interrupt
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret

main:
    ; data segments
    mov ax, 0                           ; can't directly write to ds & es
    mov ds, ax
    mov es, ax

    ; stack
    mov ss, ax
    mov sp, 0x7C00                      ; stack grows downward

    ; read disk
    ; DL should be set to drive number
    mov [ebr_drive_number], dl
    mov ax, 1                           ; LBA=1
    mov cl, 1                           ; read 1 sector
    mov bx, 0x7E00                      ; start after bootloader
    call disk_read

    ; print hello world
    mov si, msg_hello
    call puts

    cli                                 ; disable interrupts
    hlt

; Error Handling
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                             ; await keypress
    jmp 0FFFFh:0                        ; reboot BIOS

.halt:
    cli                                 ; disable interrupts
    hlt


; Disk routines

; Convert LBA to CHS
; Params:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]:    sector
;   - cx [bits 6-15]:   cylinder
;   - dh:               head
lba_to_chs:
    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [bdb_sectors_per_track]    ; ax = LBA / Sectors Per Track
                                        ; dx = LBA % Sectors Per Track

    inc dx                              ; dx = (LBA % Sectors Per Track + 1) = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [bdb_heads]                ; ax = (LBA / Sectors Per Track) / Heads = cylinder
                                        ; dx = (LBA / Sectors Per Track) % Heads = head
    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                          ; restore dl
    pop ax
    ret

; Read disk sectors
; Params:
;   - ax:       LBA address
;   - cl:       number of sectors to read (up to 128)
;   - dl:       drive number
;   - es:bx:    memory address to store read data
disk_read:

    push ax                             ; save registers
    push bx
    push cx
    push dx
    push di

    push cx                             ; temporarily save CL (number of sectors to read)
    call lba_to_chs                     ; computer CHS
    pop ax                              ; AL = number of sectors to read

    mov ah, 02h
    mov di, 3                           ; retry count

.retry
    pusha                               ; save all registers
    stc                                 ; set carry flag
    int 13h                             ; carry flag cleared = g2g
    jnc .done                           ; jump if carry not set

    ; failed read
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail
    ; max attempts
    jmp floppy_error


.done
    popa
    pop ax                              ; restore registers
    pop bx
    pop cx
    pop dx
    pop di
    ret


; Reset disk controller
; Params:
;   - dl: drive number
disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret

msg_hello:              db 'Hello world!', ENDL, 0
msg_read_failed:        db 'Disk read failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h