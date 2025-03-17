#include <stdint.h>
#include "stdio.h"
#include "x86.h"
#include "disk.h"
#include "fat.h"
#include "memdefs.h"
#include "memory.h"

uint8_t* KernelLoadBuffer = (uint8_t*)MEMORY_LOAD_KERNEL;
uint8_t* Kernel = (uint8_t*)MEMORY_KERNEL_ADDR;
typedef void (*KernelStart)();

void __attribute__((cdecl)) start(uint16_t bootDrive)
{
    clrscr();
    DISK disk;
    if (!DISK_Initialize(&disk, bootDrive))
    {
        printf("Disk initialization error!\r\n");
        goto end;
    }
    if (!FAT_Initialize(&disk))
    {
        printf("FAT initialization error!\r\n");
        goto end;
    }

    FAT_File* fd = FAT_Open(&disk, "/kernel.bin");
    uint32_t read;
    uint8_t* kernelBuffer = Kernel;
    while ((read = FAT_Read(&disk, fd, MEMORY_LOAD_SIZE, KernelLoadBuffer)))
    {
        memcpy(kernelBuffer, KernelLoadBuffer, read);
        kernelBuffer += read;
    }
    FAT_Close(fd);

    KernelStart kernelStart = (KernelStart)Kernel;
    kernelStart();

end:
    for (;;);
}