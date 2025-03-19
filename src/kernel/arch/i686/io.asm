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

global i686_Panic
i686_Panic:
    cli
    hlt


; Interrupt Testing

global divide_by_zero
divide_by_zero:
    mov ecx, 0x1337
    mov eax, 0
    div eax
    ret

global overflow
overflow:
    mov eax, 0xffffffff
    mov edx, 0xffffffff
    mov ebx, 2
    div ebx
    ret

global segment_not_present
segment_not_present:
    int 0x80
    ret