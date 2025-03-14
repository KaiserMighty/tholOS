# tholOS
x86 Operating System

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