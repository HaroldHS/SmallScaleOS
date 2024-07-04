;
; multiboot2_x86_64.asm
;
; Reference: https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html
;
; License: GPL-3.0
;

%define MULTIBOOT2_MAGIC_NUM             0xe85250d6
%define MULTIBOOT2_BOOTLOADER_MAGIC_NUM  0x36d76289

%define MULTIBOOT_ARCH_I386           0
%define MULTIBOOT_ARCH_MIPS32         4
%define MULTIBOOT_HEADER_TAG_OPTIONAL 1

%define MULTIBOOT_HEADER_TAG_END               0
%define MULTIBOOT_HEADER_TAG_INFO_REQ          1
%define MULTIBOOT_HEADER_TAG_ADDR              2
%define MULTIBOOT_HEADER_TAG_ENTRY_ADD         3
%define MULTIBOOT_HEADER_TAG_CONSOLE_FLAGS     4
%define MULTIBOOT_HEADER_TAG_FRAMEBUFFER       5
%define MULTIBOOT_HEADER_TAG_MODULE_ALIGN      6
%define MULTIBOOT_HEADER_TAG_EFI_BS            7
%define MULTIBOOT_HEADER_TAG_ENTRY_ADDR_EFI32  8
%define MULTIBOOT_HEADER_TAG_ENTRY_ADDR_EFI64  9
%define MULTIBOOT_HEADER_TAG_RELOCATABLE       10

section .multiboot2
multiboot2_header:
	dd MULTIBOOT2_MAGIC_NUM                      ; magic number
	dd MULTIBOOT_ARCH_I386                       ; architecture
	dd multiboot2_header_end - multiboot2_header ; header length
	dd -(MULTIBOOT2_MAGIC_NUM + MULTIBOOT_ARCH_I386 + (multiboot2_header_end - multiboot2_header)) ; checksum

	; add additional frame tags below (before header end tag)

	; header tag for ending the header frame
	dw MULTIBOOT_HEADER_TAG_END
	dw 0
	dw 8
multiboot2_header_end:

section .text
; import kernel_main() from kernel.c
extern kernel_main

global _start
_start:
	cli                ; clear all interrupts
	mov esp, stack_top ; set stack pointer
	call kernel_main   ; call kernel_main()
	hlt                ; halt the CPU

section .bss
	align (16)  ; 16-byte boundary allignment
stack_bottom:
	resb 16384  ; 16KB stack size
stack_top: 