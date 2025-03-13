org 0x0
bits 16

%define ENDL 0x0D, 0x0A


start:
    ; print hello world
    mov si, msg_hello
    call puts

.halt:
    cli
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
    lodsb                   ; get next char
    or al, al               ; is char null
    jz .done

    mov ah, 0x0E            ; bios interrupt
    mov bh, 0               ; set page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret

msg_hello: db 'Hello world!', ENDL, 0