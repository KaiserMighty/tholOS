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
    * Print function for debugging from inside the OS
    * VGA text mode support (direct writes to `0xB8000`)
    * E9 port hack for sending debug information directly to host
* Memory Management
    * Paging enabled
    * Basic physical memory manager
* Interrupt Handling
    * Interrupt Service Routines for CPU exceptions
    * Programmable Interrupt Controller remapping
    * Keyboard IRQ support
* Filesystem & Storage
    * Reads disk using BIOS interrupts (`INT 13h`)
    * Supports the FAT12, FAT16, FAT32, and EXT2 filesystems

# Complilation
Compiling the OS requires a good chunk of prerequisite packages.  
I developed this in Linux, within the WSL2 environment (in whatever distro WSL comes with, probably some flavor of Ubuntu).  
As such, all the tools are intended to allow me to build and test the OS in a Qemu VM from within WSL2.  
Bochs is used to debug the OS, but the ROMs needed are not included within this repo.  
For non-Debian/Ubuntu Linux distros, you can try using `scripts/install_deps.sh`, although your milage may vary because I only tested everything in WSL2.  

## Prerequisites
Create a folder called `toolchain` in the project directory, the location of this directory should be changed in `build_scripts/config.py` because it is an absolute path.  
You may need to change the binutils and GCC version within `scripts/setup_toolchain.py`.  
You may also need to add execute permissions to the shell scripts in `scripts`, you can do this with `chmod +x SCRIPT.sh` for each file within the `scripts` directory.  
```
sudo apt install build-essential bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo nasm mtools qemu-system-x86 python3 python3-scons

scons toolchain
```
If there is an error message that says the MPC packages cannot be found, try uncommenting lines 63 and 64 in `setup_toolchain.sh` and run scons `toolchain again`.  
You can clear out the toolchain directory by running `scons toolchain -c`.  

## Build
If you are not using WSL2, change `mountMethod` from `mount` to `guestfs` in `build_scripts/config.py`, this will make it so it doesn't prompt you for the sudo password when you compile.    
```
scons
scons run
```

## Debug
```
scons debug
```