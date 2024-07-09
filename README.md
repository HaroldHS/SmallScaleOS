# SmallScaleOS
SmallScaleOS is a small scale, terminal based, 64-bit operating system with a nano-kernel included.

### Requirements

##### Hardware Requirements
* x86-64 CPU
* VGA Text mode supported (Text Resolution = 160x50 / Graphics Resolution = 1280x400 / 720x512)

##### Software Requirements
* NASM
* GCC
* GDB
* GRUB
* QEMU

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

> Note: After building the ISO file, 2 other ways to run it are using virtual machine software or burn it to an external device (USB/CD) then run it via BIOS/UEFI.

### Debug with QEMU
Open a terminal, run the below script (running QEMU server and pause the operating system)
```bash
qemu-system-x86_64 -s -S ./build/SmallScaleOS.iso
```
<br />

Open another terminal, run the below script (run GDB)
```bash
gdb ./build/SmallScaleOS.bin
# Then, inside the gdb, run the command below
target remote :1234
# Set the syntax flavor to intel x86 syntax
set disassembly-flavor intel
# To put a break pointer when calling kernel_main, run the command below
break *kernel_main
```

### Error message when bootloading
* `[-] NSC` means not supported CPU. The supported CPUs for this operating system are Intel and AMD.
* `[-] NSLM` means not supporting long mode. This operating system should runs in 64-bit machine.

### Features of SmallScaleOS
- [x] Context Switching
- [ ] Interrupt
- [ ] Inter-process Communication (IPC)
- [ ] Memory Management
- [x] Paging