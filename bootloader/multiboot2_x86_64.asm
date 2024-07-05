;
; multiboot2_x86_64.asm
;
; Reference: https://www.gnu.org/software/grub/manual/multiboot2/multiboot.html
;            https://wiki.osdev.org/CPUID
;            https://en.wikipedia.org/wiki/CPUID
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

	;;;;;;;;;; Additional header tags area ;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; header tag for ending the header frame
	dw MULTIBOOT_HEADER_TAG_END
	dw 0
	dw 8
multiboot2_header_end:

section .text
; import kernel_main() from kernel.asm
extern kernel_main

global _start
_start:
	cli                  ; disable interrupts
	mov esp, stack_top   ; set stack pointer
	call check_cpuid     ; check the system CPU type
	call check_long_mode ; check if the system support long mode
	call kernel_main     ; call kernel_main()
	hlt                  ; halt the CPU

check_cpuid:
	mov eax, 0x0
	cpuid

	; when "cpuid" instruction called, if the system use x86_64 CPU, then ebx + edx + ecx = "GenuineIntel"
	;                                  if the system use AMD CPU, then ebx + edx + ecx = "AuthenticAMD"
	;
	; NOTE: since x86_64 and AMD are little-endian machines, the address mechanism is reversed (ebx != "Auth" but ebx = "htuA")
	;
	cmp ebx, 0x756e6547 ; "uneG"
	je .is_intel_cpu
	cmp ebx, 0x68747541 ; "htuA"
	je .is_amd_cpu
	jne .not_supported_cpu

	.is_intel_cpu:
		cmp edx, 0x49656e69 ; "Ieni"
		jne .not_supported_cpu
		cmp ecx, 0x6c65746e ; "letn"
		jne .not_supported_cpu
		ret

	.is_amd_cpu:
		cmp edx, 0x69746e65 ; "itne"
		jne .not_supported_cpu
		cmp ecx, 0x444d4163 ; "DMAc"
		jne .not_supported_cpu
		ret

	.not_supported_cpu:
		; write "[-] NSC" to VGA buffer
		mov dword [0xb8000], 0x0f2d0f5b
		mov dword [0xb8004], 0x0f200f5d
		mov dword [0xb8008], 0x0f530f4e
		mov dword [0xb800c], 0x0f43
		hlt

check_long_mode:
	mov eax, 0x80000001
	cpuid
	test edx, 1 << 29
	jz .not_supported_long_mode
	ret

	.not_supported_long_mode:
		; write "[-] NSLM" to VGA buffer
		mov dword [0xb8000], 0x0f2d0f5b
		mov dword [0xb8004], 0x00020f5d
		mov dword [0xb8008], 0x0f530f4e
		mov dword [0xb800c], 0x0f4d0f4c
		hlt

section .bss
	align (16)  ; 16-byte boundary allignment
stack_bottom:
	resb 16384  ; 16KB stack size
stack_top: 