# tholOS
x86 Operating System

## Prerequisites
```
apt install make
apt install nasm
apt install qemu-system-i386
```

## Build
```
make
qemu-system-i386 -fda build/main_floppy.img
```