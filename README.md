# SmallScaleOS
SmallScaleOS is a small scale, terminal based, operating system with a nano-kernel included.

### Requirements
* NASM
* GCC
* QEMU
* GRUB

> Note: To run the operating system in WSL(Ubuntu), run this command in order to build a successful build-file `sudo apt install make grub-common xorriso grub-pc-bin`.

### Build / Run / Clean project
```bash
# 1. Build an ISO image
make build_iso

# 2.a Run the ISO image
qemu-system-x86_64 -cdrom ./build/SmallScaleOS.iso

# 2.b Run the kernel via binary file
qemu-system-x86_64 -kernel ./build/SmallScaleOS.bin

# 3. Clean the project
make clean
```

> Note: After building the ISO file, 2 other ways to run it are using virtual machine software or burn it to an external device (USB/CD) then run it via BIOS.

### Features of SmallScaleOS
- [ ] Context Switching
- [ ] Interrupt
- [ ] Inter-process Communication (IPC)
- [ ] Memory Management