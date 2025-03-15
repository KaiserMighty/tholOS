bits 16

section _TEXT class=CODE


global __U4D
__U4D:
    shl edx, 16         ; upper half of edx
    mov dx, ax          ; dividend
    mov eax, edx        ; dividend
    xor edx, edx

    shl ecx, 16         ; upper half of ecx
    mov cx, bx          ; divisor

    div ecx             ; eax - quot, edx - remainder
    mov ebx, edx
    mov ecx, edx
    shr ecx, 16

    mov edx, eax
    shr edx, 16

    ret


global __U4M
__U4M:
    shl edx, 16         ; upper half of edx
    mov dx, ax          ; m1
    mov eax, edx        ; m1

    shl ecx, 16         ; upper half of ecx
    mov cx, bx          ; m2

    mul ecx             ; we only need eax
    mov edx, eax        ; upper half
    shr edx, 16

    ret


global _x86_div64_32
_x86_div64_32:
    push bp             ; save old call frame
    mov bp, sp          ; init new call frame
    push bx             ; save bx

    ; divide upper 32 bits
    mov eax, [bp + 8]   ; upper 32 bits of dividend
    mov ecx, [bp + 12]  ; divisor
    xor edx, edx
    div ecx             ; quotient

    ; store upper 32 bits of quotient
    mov bx, [bp + 16]   ; store upper 32 bits of quotient
    mov [bx + 4], eax

    ; divide lower 32 bits
    mov eax, [bp + 4]   ; lower 32 bits of dividend
    div ecx

    ; results
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx       ; remainder

    pop bx              ; restore bx
    mov sp, bp          ; destroy new call frame
    pop bp              ; restore old call frame
    ret


global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
    push bp             ; save old call frame
    mov bp, sp          ; init new call frame
    push bx             ; save bx

    ; [bp + 0] - old call frame
    ; [bp + 2] - return address (small memory model)
    ; [bp + 4] - first argument (character)
    ; [bp + 6] - second argument (page)
    mov ah, 0Eh
    mov al, [bp + 4]
    mov bh, [bp + 6]
    int 10h

    pop bx              ; restore bx
    mov sp, bp          ; destroy new call frame
    pop bp              ; restore old call frame
    ret


global _x86_Disk_Reset
_x86_Disk_Reset:
    push bp             ; save old call frame
    mov bp, sp          ; init new call frame

    mov ah, 0
    mov dl, [bp + 4]    ; drive
    stc
    int 13h

    mov ax, 1
    sbb ax, 0           ; 1 on success, 0 on fail

    mov sp, bp          ; destroy new call frame
    pop bp              ; restore old call frame
    ret


global _x86_Disk_Read
_x86_Disk_Read:
    push bp             ; save old call frame
    mov bp, sp          ; init new call frame

    ; save registers
    push bx
    push es

    ; setup arguments
    mov dl, [bp + 4]    ; drive

    mov ch, [bp + 6]    ; cylinder (lower 8 bits)
    mov cl, [bp + 7]    ; cylinder to bits 6-7
    shl cl, 6

    mov al, [bp + 8]    ; sector to bits 0-5
    and al, 3Fh
    or cl, al

    mov dh, [bp + 10]   ; head

    mov al, [bp + 12]   ; count

    mov bx, [bp + 16]   ; far pointer to data out
    mov es, bx
    mov bx, [bp + 14]

    ; call int 13h
    mov ah, 02h
    stc
    int 13h

    ; return
    mov ax, 1
    sbb ax, 0           ; 1 on success, 0 on fail

    ; restore registers
    pop es
    pop bx

    mov sp, bp          ; destroy new call frame
    pop bp              ; restore old call frame
    ret


global _x86_Disk_GetDriveParams
_x86_Disk_GetDriveParams:
    push bp             ; save old call frame
    mov bp, sp          ; init new call frame

    ; save registers
    push es
    push bx
    push si
    push di

    ; call int13h
    mov al, [bp + 4]    ; disk drive
    mov ah, 08h
    mov di, 0           ; 0000:0000
    mov es, di
    stc
    int 13h

    ; return
    mov ax, 1
    sbb ax, 0

    ; out parameters
    mov si, [bp + 6]    ; drive type
    mov [si], bl

    mov bl, ch          ; lower cylinders bits
    mov bh, cl          ; upper cylinders bits (6-7)
    shr bh, 6
    mov si, [bp + 8]
    mov [si], bx

    xor ch, ch          ; lower 5 bits of sectors
    and cl, 3Fh
    mov si, [bp + 10]
    mov [si], cx

    mov cl, dh          ; heads
    mov si, [bp + 12]
    mov [si], cx

    ; restore registers
    pop di
    pop si
    pop bx
    pop es

    mov sp, bp          ; destroy new call frame
    pop bp              ; restore old call frame
    ret
