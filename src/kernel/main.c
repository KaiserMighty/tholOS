#include <stdint.h>
#include "stdio.h"
#include "memory.h"
#include <hal/hal.h>
#include <arch/i686/irq.h>
#include <debug.h>

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

    log_debug("Main", "Debug Message Test!");
    log_info("Main", "Debug Info Message Test!");
    log_warn("Main", "Debug Warning Message Test!");
    log_err("Main", "Debug Error Message Test!");
    log_crit("Main", "Debug Critical Message Test!");

    printf("Hello world!\n");
    debugf("Debug Port E5!\n");
    debugf("\033[34mDebug Colors Port E5!\033[0m\n");

    // divide_by_zero();
    // overflow();
    // segment_not_present();
    
    i686_IRQ_RegisterHandler(0, timer);

end:
    for (;;);
}