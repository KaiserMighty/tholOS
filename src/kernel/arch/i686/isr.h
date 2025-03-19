#pragma once
#include <stdint.h>

typedef struct 
{
    // in reverse order
    uint32_t ds;                                            // data segment
    uint32_t edi, esi, ebp, useless, ebx, edx, ecx, eax;    // pusha
    uint32_t interrupt, error;
    uint32_t eip, cs, eflags, esp, ss;                      // pushed by CPU
} __attribute__((packed)) Registers;

typedef void (*ISRHandler)(Registers* regs);

void i686_ISR_Initialize();
void i686_ISR_RegisterHandler(int interrupt, ISRHandler handler);