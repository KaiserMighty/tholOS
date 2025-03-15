# tholOS
The tholOS (Tholos: from Ancient Greek, meaning "conical roof" or "dome") operating system is a Hobbyist x86 Operating System developed for fun and to improve my understanding of how Operating Systems work.  

### Features
* Custom Bootloader
    * Multi-stage bootloader (Stage 1 in 512-byte MBR, Stage 2 for extended functionality)
    * Loads the kernel from disk
* Basic Kernel
    * Written in C and Assembly
    * Sets up protected mode for 32-bit execution
    * Implements Global Descriptor Table
    * Uses Interrupt Descriptor Table for exceptions and IRQs
* Standard Input/Output
    * Basic print function for debugging
    * VGA text mode support (direct writes to `0xB8000`)
* Memory Management
    * Paging enabled
    * Basic physical memory manager
* Interrupt Handling
    * Interrupt Service Routines for CPU exceptions
    * Programmable Interrupt Controller remapping
    * Keyboard IRQ support
* Filesystem & Storage
    * Reads disk using BIOS interrupts (`INT 13h`)
    * Initial support for FAT12 filesystem

Note: Not all of these features may be complete at present time, but all above mentioned features are planned.

# Complilation
Compiling the OS requires a good chunk of prerequisite packages.  
I developed this in Linux, within the WSL2 environment (in whatever distro WSL comes with, probably some flavor of Ubuntu).  
As such, all the tools are intended to allow me to build and test the OS in a Qemu VM from within WSL2.  
There are shell scripts included to make running "easy".  
Bochs is used to debug the OS, but the ROMs needed are not included within this repo.

## Prerequisites
```
apt install make nasm qemu-system-i386
apt install dosfstools mtools
apt install bochs bochs-sdl bochsbios vgabios
```
Needs [Open Watcom 2](https://github.com/open-watcom/open-watcom-v2) to compile bootloader in 16-Bit Real Mode.  
Make sure the "Include 16-bit compilers" option is selected in the components menu.  

## Build
```
make
chmod +x run.sh
./run.sh
```

## Debug
```
chmod +x debug.sh
./run.debug
```