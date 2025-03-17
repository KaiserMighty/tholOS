%macro x86_EnterRealMode 0
    [bits 32]
    jmp word 18h:.pmode16       ; jump to 16-bit protected mode segment

.pmode16:
    [bits 16]
    mov eax, cr0                ; disable protected mode bit in cr0
    and al, ~1
    mov cr0, eax
    jmp word 00h:.rmode         ; jump to real mode

.rmode:
    mov ax, 0                   ; setup segments
    mov ds, ax
    mov ss, ax
    sti                         ; enable interrupts
%endmacro


%macro x86_EnterProtectedMode 0
    cli
    mov eax, cr0                ; set protection enable flag in CR0
    or al, 1
    mov cr0, eax
    jmp dword 08h:.pmode        ; far jump into protected mode

.pmode:
    [bits 32]
    mov ax, 0x10                ; setup segment registers
    mov ds, ax
    mov ss, ax
%endmacro

; linear address to segment:offset address
; Params:
;   1 linear address
;   2 target segment
;   3 target 32-bit register to use
;   4 target lower 16-bit half of #3
%macro LinearToSegOffset 4
    mov %3, %1                  ; linear address to eax
    shr %3, 4
    mov %2, %4
    mov %3, %1                  ; linear address to eax
    and %3, 0xf
%endmacro


global x86_outb
x86_outb:
    [bits 32]
    mov dx, [esp + 4]
    mov al, [esp + 8]
    out dx, al
    ret

global x86_inb
x86_inb:
    [bits 32]
    mov dx, [esp + 4]
    xor eax, eax
    in al, dx
    ret


global x86_Disk_GetDriveParams
x86_Disk_GetDriveParams:
    [bits 32]

    ; make new call frame
    push ebp                    ; save old call frame
    mov ebp, esp                ; initialize new call frame

    x86_EnterRealMode

    [bits 16]

    ; save regs
    push es
    push bx
    push esi
    push di

    ; call int13h
    mov dl, [bp + 8]            ; disk drive
    mov ah, 08h
    mov di, 0                   ; es:di - 0000:0000
    mov es, di
    stc
    int 13h

    ; out params
    mov eax, 1
    sbb eax, 0

    ; drive type from bl
    LinearToSegOffset [bp + 12], es, esi, si
    mov [es:si], bl

    ; cylinders
    mov bl, ch                  ; lower cylinders bits
    mov bh, cl                  ; upper cylinders bits (6-7)
    shr bh, 6
    inc bx

    LinearToSegOffset [bp + 16], es, esi, si
    mov [es:si], bx

    ; sectors
    xor ch, ch                  ; lower 5 sectors bits
    and cl, 3Fh
    
    LinearToSegOffset [bp + 20], es, esi, si
    mov [es:si], cx

    ; heads
    mov cl, dh                  ; heads
    inc cx

    LinearToSegOffset [bp + 24], es, esi, si
    mov [es:si], cx

    ; restore regs
    pop di
    pop esi
    pop bx
    pop es

    ; return
    push eax
    x86_EnterProtectedMode
    [bits 32]
    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret


global x86_Disk_Reset
x86_Disk_Reset:
    [bits 32]

    ; make new call frame
    push ebp                    ; save old call frame
    mov ebp, esp                ; initialize new call frame


    x86_EnterRealMode

    mov ah, 0
    mov dl, [bp + 8]            ; drive
    stc
    int 13h

    mov eax, 1
    sbb eax, 0                  ; 1 on success, 0 on fail   

    push eax
    x86_EnterProtectedMode
    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret


global x86_Disk_Read
x86_Disk_Read:

    ; make new call frame
    push ebp                    ; save old call frame
    mov ebp, esp                ; initialize new call frame

    x86_EnterRealMode

    ; save modified regs
    push ebx
    push es

    ; setup args
    mov dl, [bp + 8]            ; drive
    mov ch, [bp + 12]           ; lower cylinders bits
    mov cl, [bp + 13]           ; upper cylinders bits (6-7)
    shl cl, 6
    mov al, [bp + 16]           ; lower 5 sectors bits
    and al, 3Fh
    or cl, al
    mov dh, [bp + 20]           ; head
    mov al, [bp + 24]           ; count
    LinearToSegOffset [bp + 28], es, ebx, bx

    ; call int13h
    mov ah, 02h
    stc
    int 13h

    ; set return value
    mov eax, 1
    sbb eax, 0                  ; 1 on success, 0 on fail   

    ; restore regs
    pop es
    pop ebx

    push eax
    x86_EnterProtectedMode
    pop eax

    ; restore old call frame
    mov esp, ebp
    pop ebp
    ret