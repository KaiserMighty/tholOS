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
    ; data segments
    mov ax, 0                           ; can't directly write to ds & es
    mov ds, ax
    mov es, ax

    ; stack
    mov ss, ax
    mov sp, 0x7C00                      ; stack grows downward

    ; BIOS edge-case
    push es
    push word .after
    retf

.after:
    ; read disk
    ; DL should be set to drive number
    mov [ebr_drive_number], dl

    ; show loading message
    mov si, msg_loading
    call puts

    ; read drive parameters
    push es
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es

    and cl, 0x3F                        ; remove top 2 bits
    xor ch, ch
    mov [bdb_sectors_per_track], cx     ; sector count

    inc dh
    mov [bdb_heads], dh                 ; head count

    ; compute LBA of root directory = reserved + fats * sectors_per_fat
    ; this section can be hardcoded
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                              ; ax = (fats * sectors_per_fat)
    add ax, [bdb_reserved_sectors]      ; ax = LBA of root directory
    push ax

    ; compute size of root directory = (32 * number_of_entries) / bytes_per_sector
    mov ax, [bdb_dir_entries_count]
    shl ax, 5                           ; ax *= 32
    xor dx, dx                          ; dx = 0
    div word [bdb_bytes_per_sector]     ; number of sectors we need to read

    test dx, dx                         ; if dx != 0, add 1
    jz .root_dir_after
    inc ax                              ; division remainder != 0, add 1
                                        ; this means we have a partially filled sector 

.root_dir_after:
    ; read root directory
    mov cl, al                          ; cl = number of sectors to read = size of root directory
    pop ax                              ; ax = LBA of root directory
    mov dl, [ebr_drive_number]          ; dl = drive number (previously saved)
    mov bx, buffer                      ; es:bx = buffer
    call disk_read

    ; search for stage2.bin
    xor bx, bx
    mov di, buffer

.search_stage2:
    mov si, file_stage2_bin
    mov cx, 11                          ; max file size is 11
    push di
    repe cmpsb
    pop di
    je .found_stage2

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .search_stage2

    ; stage2 not found
    jmp stage2_not_found_error

.found_stage2:
    ; di = entry address
    mov ax, [di + 26]                   ; first logical cluster field (26)
    mov [stage2_cluster], ax

    ; load FAT from disk into memory
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    ; read stage2 and process FAT chain
    mov bx, STAGE2_LOAD_SEGMENT
    mov es, bx
    mov bx, STAGE2_LOAD_OFFSET

.load_stage2_loop:
    ; read next cluster
    mov ax, [stage2_cluster]
    add ax, 31                          ; first cluster = (cluster number - 2) * sectors_per_cluster + start_sector
                                        ; start sector = reserved + fats + root directory size = 1 + 18 + 134 = 33

    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]

    ; compute location of next cluster
    mov ax, [stage2_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                              ; ax = index of entry in FAT, dx = cluster mod 2

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                     ; read entry from FAT table at index ax

.even:
    shr ax, 4
    jmp .next_cluster_after

.odd:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0FF8                      ; end of chain
    jae .read_finish

    mov [stage2_cluster], ax
    jmp .load_stage2_loop

.read_finish:
    ; jump to stage2
    mov dl, [ebr_drive_number]          ; boot device in dl

    mov ax, STAGE2_LOAD_SEGMENT         ; set segment registers
    mov ds, ax
    mov es, ax

    jmp STAGE2_LOAD_SEGMENT:STAGE2_LOAD_OFFSET

    jmp wait_key_and_reboot             ; should be unreachable

    cli                                 ; disable interrupts
    hlt

; Error Handling
floppy_error:
    mov si, msg_read_failed
    call puts
    jmp wait_key_and_reboot

stage2_not_found_error:
    mov si, msg_stage2_not_found
    call puts
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 16h                             ; await keypress
    jmp 0FFFFh:0                        ; reboot BIOS

.halt:
    cli                                 ; disable interrupts
    hlt


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

.retry:
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

.fail:
    ; max attempts
    jmp floppy_error


.done:
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

msg_loading:            db 'Loading...', ENDL, 0
msg_read_failed:        db 'Disk read failed!', ENDL, 0
msg_stage2_not_found:   db 'STAGE2.BIN file not found!', ENDL, 0
file_stage2_bin         db 'STAGE2  BIN'
stage2_cluster          dw 0

STAGE2_LOAD_SEGMENT      equ 0x2000
STAGE2_LOAD_OFFSET      equ 0

times 510-($-$$) db 0
dw 0AA55h

buffer: