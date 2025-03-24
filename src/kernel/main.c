#include <stdint.h>
#include "stdio.h"
#include "memory.h"
#include <hal/hal.h>
#include <arch/i686/irq.h>

extern uint8_t __bss_start;
extern uint8_t __end;

extern void _init();

void divide_by_zero();
void overflow();
void segment_not_present();

void timer(Registers* regs)
{
    printf("Timer Interrupt!\n");
}

void __attribute__((section(".entry"))) start(uint16_t bootDrive)
{
    memset(&__bss_start, 0, (&__end) - (&__bss_start));
    _init();
    HAL_Initialize();
    clrscr();
    printf("Hello world!\n");

    // divide_by_zero();
    // overflow();
    // segment_not_present();
    
    i686_IRQ_RegisterHandler(0, timer);

end:
    for (;;);
}