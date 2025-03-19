[bits 32]

extern i686_ISR_Handler

%macro ISR_NOERRORCODE 1
global i686_ISR%1:
i686_ISR%1:
    push 0              ; dummy error code
    push %1             ; interrupt number
    jmp isr_common
%endmacro

%macro ISR_ERRORCODE 1
global i686_ISR%1:
i686_ISR%1:             ; cpu pushed a code to stack
    push %1             ; interrupt number
    jmp isr_common
%endmacro

%include "arch/i686/isrs_gen.inc"

isr_common:
    pusha               ; eax, ecx, edx, ebx, esp, ebp, esi, edi

    xor eax, eax        ; push ds
    mov ax, ds
    push eax

    mov ax, 0x10        ; kernel data segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    push esp            ; pass stack to C
    call i686_ISR_Handler
    add esp, 4

    pop eax             ; restore old segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    popa                ; restore push
    add esp, 8          ; error code and interrupt number
    iret                ; pop cs, eip, eflags, ss, esp