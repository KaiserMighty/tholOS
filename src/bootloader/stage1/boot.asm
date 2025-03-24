bits 16

%define ENDL 0x0D, 0x0A


section .fsjump
    jmp short start
    nop

section .fsheaders
    bdb_oem:                    db "abcdefgh"           ; 8 bytes
    bdb_bytes_per_sector:       dw 512
    bdb_sectors_per_cluster:    db 1
    bdb_reserved_sectors:       dw 1
    bdb_fat_count:              db 2
    bdb_dir_entries_count:      dw 0E0h
    bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
    bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
    bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
    bdb_sectors_per_track:      dw 18
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
section .entry
    global start

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

        ; check extensions present
        mov ah, 0x41
        mov bx, 0x55AA
        stc
        int 13h

        jc .no_disk_extensions
        cmp bx, 0xAA55
        jne .no_disk_extensions

        ; extensions are present
        mov byte [have_extensions], 1
        jmp .after_disk_extensions_check

    .no_disk_extensions:
        mov byte [have_extensions], 0

    .after_disk_extensions_check:
        ; load stage2
        mov si, stage2_location

        mov ax, STAGE2_LOAD_SEGMENT         ; set segment registers
        mov es, ax

        mov bx, STAGE2_LOAD_OFFSET

    .loop:
        mov eax, [si]
        add si, 4
        mov cl, [si]
        inc si

        cmp eax, 0
        je .read_finish

        call disk_read

        xor ch, ch
        shl cx, 5
        mov di, es
        add di, cx
        mov es, di

        jmp .loop

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

section .text
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
        push bx

    .loop:
        lodsb                               ; get next char
        or al, al                           ; is char null
        jz .done

        mov ah, 0x0E                        ; bios interrupt
        mov bh, 0                           ; page number = 0
        int 0x10

        jmp .loop

    .done:
        pop bx
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
        push eax                            ; save registers
        push bx
        push cx
        push dx
        push si
        push di

        cmp byte [have_extensions], 1
        jne .no_disk_extensions

        ; with extensions
        mov [extensions_dap.lba], eax
        mov [extensions_dap.segment], es
        mov [extensions_dap.offset], bx
        mov [extensions_dap.count], cl

        mov ah, 0x42
        mov si, extensions_dap
        mov di, 3                           ; retry count
        jmp .retry

    .no_disk_extensions:
        push cx                             ; save number of sectors to read
        call lba_to_chs
        pop ax                              ; number of sectors to read
        
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
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop eax                             ; restore registers
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

section .rodata
    msg_loading:            db 'Loading...', ENDL, 0
    msg_read_failed:        db 'Disk read failed!', ENDL, 0
    msg_stage2_not_found:   db 'STAGE2.BIN file not found!', ENDL, 0
    file_stage2_bin:        db 'STAGE2  BIN'

section .data
    have_extensions:        db 0
    extensions_dap:
        .size:              db 10h
                            db 0
        .count:             dw 0
        .offset:            dw 0
        .segment:           dw 0
        .lba:               dq 0

    STAGE2_LOAD_SEGMENT     equ 0x0
    STAGE2_LOAD_OFFSET      equ 0x500

section .data
    global stage2_location
    stage2_location:        times 30 db 0

section .bss
    buffer:                 resb 512