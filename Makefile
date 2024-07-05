ASM=nasm
CC=gcc
LINKER=ld
GRUB=grub-mkrescue

# Flags for programs
ASMFLAGS = -g -f elf64
CCFLAGS= -fno-builtin -c

BUILD_DIR=build
KERNEL_DIR=kernel
BOOTLOADER_DIR = bootloader
BOOT_DIR=$(BOOTLOADER_DIR)/boot

# List of object files
ASSEMBLY_SOURCE_FILES=$(shell find $(BOOTLOADER_DIR) -name *.asm)
ASSEMBLY_OBJECT_FILES=$(patsubst $(BOOTLOADER_DIR)/%.asm, $(BUILD_DIR)/%.o, $(ASSEMBLY_SOURCE_FILES))
KERNEL_SOURCE_FILES=$(shell find $(KERNEL_DIR) -name *.asm)
KERNEL_OBJECT_FILES=$(patsubst $(KERNEL_DIR)/%.asm, $(BUILD_DIR)/%.o, $(KERNEL_SOURCE_FILES))

.PHONY: build_iso clean

build_iso: $(BUILD_DIR)/SmallScaleOS.iso
# Generate ISO image
$(BUILD_DIR)/SmallScaleOS.iso : $(BOOT_DIR)/SmallScaleOS.bin
	$(GRUB) -o $(BUILD_DIR)/SmallScaleOS.iso $(BOOTLOADER_DIR)
# Copy build result to /boot
$(BOOT_DIR)/SmallScaleOS.bin : $(BUILD_DIR)/SmallScaleOS.bin
	cp $(BUILD_DIR)/SmallScaleOS.bin $(BOOT_DIR)/SmallScaleOS.bin
# Generate binary image with linker
$(BUILD_DIR)/SmallScaleOS.bin : $(BOOTLOADER_DIR)/linker.ld $(ASSEMBLY_OBJECT_FILES) $(KERNEL_OBJECT_FILES)
	$(LINKER) -m elf_x86_64 -T $(BOOTLOADER_DIR)/linker.ld -o $(BUILD_DIR)/SmallScaleOS.bin $(ASSEMBLY_OBJECT_FILES) $(KERNEL_OBJECT_FILES)
# Generate object files
$(ASSEMBLY_OBJECT_FILES) : $(BUILD_DIR)/%.o : $(BOOTLOADER_DIR)/%.asm
	mkdir -p $(dir $@) && $(ASM) $(ASMFLAGS) $(patsubst $(BUILD_DIR)/%.o, $(BOOTLOADER_DIR)/%.asm, $@) -o $@
$(KERNEL_OBJECT_FILES): $(BUILD_DIR)/%.o : $(KERNEL_DIR)/%.asm
	mkdir -p $(dir $@) && $(ASM) $(ASMFLAGS) $(patsubst $(BUILD_DIR)/%.o, $(KERNEL_DIR)/%.asm, $@) -o $@

clean:
	rm -rf ./build/*
	rm ./bootloader/boot/SmallScaleOS.bin