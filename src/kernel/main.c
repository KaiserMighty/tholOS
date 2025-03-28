#include <stdint.h>
#include "stdio.h"
#include "memory.h"
#include <hal/hal.h>
#include <arch/i686/irq.h>
#include <debug.h>
#include <boot/bootparams.h>

extern void _init();

void divide_by_zero();
void overflow();
void segment_not_present();

void timer(Registers* regs)
{
    printf("Timer Interrupt!\n");
}

void start(BootParams* bootParams)
{
    _init();
    HAL_Initialize();

    log_debug("Main", "Debug Message Test!");
    log_info("Main", "Debug Info Message Test!");
    log_warn("Main", "Debug Warning Message Test!");
    log_err("Main", "Debug Error Message Test!");
    log_crit("Main", "Debug Critical Message Test!");

    log_debug("Main", "Boot device: %x", bootParams->BootDevice);
    log_debug("Main", "Memory region count: %d", bootParams->Memory.RegionCount);
    for (int i = 0; i < bootParams->Memory.RegionCount; i++) 
    {
        log_debug("Main", "  start=0x%llx length=0x%llx type=%x", 
            bootParams->Memory.Regions[i].Begin,
            bootParams->Memory.Regions[i].Length,
            bootParams->Memory.Regions[i].Type);
    }

    printf("Hello world!\n");

    // divide_by_zero();
    // overflow();
    // segment_not_present();
    
    i686_IRQ_RegisterHandler(0, timer);

end:
    for (;;);
}