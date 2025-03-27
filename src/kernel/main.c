#include <stdint.h>
#include "stdio.h"
#include "memory.h"
#include <hal/hal.h>
#include <arch/i686/irq.h>
#include <debug.h>

extern void _init();

void divide_by_zero();
void overflow();
void segment_not_present();

void timer(Registers* regs)
{
    printf("Timer Interrupt!\n");
}

void start(uint16_t bootDrive)
{
    _init();
    HAL_Initialize();

    log_debug("Main", "Debug Message Test!");
    log_info("Main", "Debug Info Message Test!");
    log_warn("Main", "Debug Warning Message Test!");
    log_err("Main", "Debug Error Message Test!");
    log_crit("Main", "Debug Critical Message Test!");

    printf("Hello world!\n");

    // divide_by_zero();
    // overflow();
    // segment_not_present();
    
    i686_IRQ_RegisterHandler(0, timer);

end:
    for (;;);
}