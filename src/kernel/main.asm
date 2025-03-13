org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A


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
    lodsb                   ; get next char
    or al, al               ; is char null
    jz .done

    mov ah, 0x0e            ; bios interrupt
    mov bh, 0
    int 0x10

    jmp .loop

.done:
    pop ax
    pop si
    ret

main:
    ; data segments
    mov ax, 0               ; can't directly write to ds & es
    mov ds, ax
    mov es, ax

    ; stack
    mov ss, ax
    mov sp, 0x7C00          ; stack grows downward

    ; print hello world
    mov si, msg_hello
    call puts

    ; temp
    hlt

.halt:
    jmp .halt


msg_hello: db 'Hello world!', ENDL, 0


times 510-($-$$) db 0
dw 0AA55h