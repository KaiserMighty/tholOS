#include "disk.h"
#include "x86.h"
#include "stdio.h"

bool DISK_Initialize(DISK* disk, uint8_t driveNumber)
{
    uint8_t driveType;
    uint16_t cylinders, sectors, heads;

    if (!x86_Disk_GetDriveParams(driveNumber, &driveType, &cylinders, &sectors, &heads))
        return false;

    disk->id = driveNumber;
    disk->cylinders = cylinders;
    disk->sectors = sectors;
    disk->heads = heads;

    return true;
}

void DISK_LBA2CHS(DISK* disk, uint32_t lba, uint16_t* cylinderOut, uint16_t* sectorOut, uint16_t* headOut)
{
    *cylinderOut = (lba / disk->sectors) / disk->heads;
    *sectorOut = lba % disk->sectors + 1;
    *headOut = (lba / disk->sectors) % disk->heads;
}

bool DISK_ReadSectors(DISK* disk, uint32_t lba, uint8_t sectors, void* dataOut)
{
    uint16_t cylinder, sector, head;
    DISK_LBA2CHS(disk, lba, &cylinder, &sector, &head);

    for (int i = 0; i < 3; i++)
    {
        if (x86_Disk_Read(disk->id, cylinder, sector, head, sectors, dataOut))
            return true;

        x86_Disk_Reset(disk->id);
    }
    return false;
}