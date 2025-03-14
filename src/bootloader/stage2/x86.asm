bits 16

section _TEXT class=CODE


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