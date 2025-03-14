bits 16

section _TEXT class=CODE

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
    mov bh, [bp + 8]
    int 10h

    pop bx              ; restore bx
    mov sp, bp          ; destroy new call frame
    pop bp              ; restore old call frame
    ret