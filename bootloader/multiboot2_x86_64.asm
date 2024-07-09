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
	dd MULTIBOOT2_MAGIC_NUM                       ; magic number
	dd MULTIBOOT_ARCH_I386                        ; architecture
	dd multiboot2_header_end - multiboot2_header  ; header length
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
bits 32

; import kernel_main() from kernel.asm
extern kernel_main

global _start
_start:
	cli                                        ; clear/disable interrupt when inside real mode
	mov esp, stack_top                         ; set stack pointer
	call check_cpuid                           ; check the system CPU type
	call check_long_mode                       ; check if the system support long mode
	call setup_page_table                      ; setup paging mechanism
	call enable_paging                         ; enable paging

	; write "[+] OK" to VGA buffer
	mov dword [0xb8140], 0x0f2b0f5b
	mov dword [0xb8144], 0x0f200f5d
	mov dword [0xb8148], 0x0f4b0f4f

	lgdt [GDT64.pointer]                       ; load GDT
	jmp GDT64.kernel_code_segment:kernel_main  ; call kernel_main using kernel code segment mode
	hlt                                        ; halt the CPU




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Perform machine checks
;
; Reference: https://wiki.osdev.org/CPUID
;            https://en.wikipedia.org/wiki/CPUID
;
; License: GPL-3.0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

check_cpuid:
	mov eax, 0x0
	cpuid

	; write "[*] Check CPU id...." VGA buffer (Row 0)
	mov dword [0xb8000], 0x0f2a0f5b
	mov dword [0xb8004], 0x0f200f5d
	mov dword [0xb8008], 0x0f680f43
	mov dword [0xb800c], 0x0f630f65
	mov dword [0xb8010], 0x0f200f6b
	mov dword [0xb8014], 0x0f500f43
	mov dword [0xb8018], 0x0f200f55
	mov dword [0xb801c], 0x0f640f69
	mov dword [0xb8020], 0x0f2e0f2e
	mov dword [0xb8024], 0x0f2e0f2e


	; when "cpuid" instruction called, if the system use x86_64 CPU, then ebx + edx + ecx = "GenuineIntel"
	;                                  if the system use AMD CPU, then ebx + edx + ecx = "AuthenticAMD"
	;
	; NOTE: since x86_64 and AMD are little-endian machines, the address mechanism is reversed (ebx != "Auth" but ebx = "htuA")
	;
	cmp ebx, 0x756e6547  ; "uneG"
	je .is_intel_cpu
	cmp ebx, 0x68747541  ; "htuA"
	je .is_amd_cpu
	jne .not_supported_cpu

	.is_intel_cpu:
		cmp edx, 0x49656e69  ; "Ieni"
		jne .not_supported_cpu
		cmp ecx, 0x6c65746e  ; "letn"
		jne .not_supported_cpu
		ret

	.is_amd_cpu:
		cmp edx, 0x69746e65  ; "itne"
		jne .not_supported_cpu
		cmp ecx, 0x444d4163  ; "DMAc"
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
	; write "[*] Check long mode availability...." VGA buffer (Row 1)
	mov dword [0xb80a0], 0x0f2a0f5b
	mov dword [0xb80a4], 0x0f200f5d
	mov dword [0xb80a8], 0x0f680f43
	mov dword [0xb80ac], 0x0f630f65
	mov dword [0xb80b0], 0x0f200f6b
	mov dword [0xb80b4], 0x0f6f0f6c
	mov dword [0xb80b8], 0x0f670f6e
	mov dword [0xb80bc], 0x0f6d0f20
	mov dword [0xb80c0], 0x0f640f6f
	mov dword [0xb80c4], 0x0f200f65
	mov dword [0xb80c8], 0x0f760f61
	mov dword [0xb80cc], 0x0f690f61
	mov dword [0xb80d0], 0x0f610f6c
	mov dword [0xb80d4], 0x0f690f62
	mov dword [0xb80d8], 0x0f690f6c
	mov dword [0xb80dc], 0x0f790f74
	mov dword [0xb80e0], 0x0f2e0f2e
	mov dword [0xb80e4], 0x0f2e0f2e

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Paging implementation (identity paging, 48-bit virtual address space, 4KB pages)
;
; Reference: https://wiki.osdev.org/Paging
;            https://wiki.osdev.org/Page_Frame_Allocation
;            https://wiki.osdev.org/Page_Tables
;            https://wiki.osdev.org/CPU_Registers_x86-64
;            https://wiki.osdev.org/Higher_Half_Kernel
;            https://wiki.osdev.org/Higher_Half_x86_Bare_Bones
;            https://wiki.osdev.org/Identity_Paging
;            https://wiki.osdev.org/Setting_Up_Long_Mode
;
; License: GPL-3.0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setup_page_table:
	; setup PML4 in order to point to PDPT
	mov eax, PDPT
	or eax, 0b11          ; setup paging directory flag, R/W = 1 (0 = read only, 1 = writeable) & P = 1 (present)
	mov [PML4], eax       ; first entry of PML4 is address of PDP

	; setup PDPT in order to point to PDT
	mov eax, PDT
	or eax, 0b11
	mov [PDPT], eax

	; setup PDT in order to point to PT
	mov eax, PT
	or eax, 0b11
	mov [PDT], eax

	; identity map Page Table (PT)
	mov ecx, 0
	.map_PT:
		mov eax, 0x1000          ; PT has 4KB range (0x1000)
		mul ecx
		or eax, 0b10000011       ; setup paging table flag, PAT=1 & R/W=1 & P=1
		mov [PT + ecx * 8], eax  ; set each page entry

		inc ecx
		cmp ecx, 512
		jne .map_PT
		ret

enable_paging:
	; Disable paging by clearing CR0 (CR0.PG = 0)
	mov ebx, cr0
	and ebx, ~(1 << 31)
	mov cr0, ebx

	; Enable Physical Address Extension (PAE)
	mov edx, cr4
	or edx, (1 << 5)
	mov cr4, edx

	; Enable Long Mode
	mov ecx, 0xc0000080
	rdmsr
	or eax, (1 << 8)
	wrmsr
	
	; Set PML4
	mov eax, PML4
	mov cr3, eax

	; Enable paging
	mov eax, cr0
	or eax, (1 << 31) | (1 << 0)  ; enable paging and protected mode (CR0.P = 1, CR0.PE = 1)
	mov cr0, eax
	ret

section .bss
align 4096      ; 4KB boundary allignment
PML4:           ; level 4 page table (Page Map Level 4)
	resb 4096
PDPT:            ; level 3 page table (Page Directory Pointer Table)
	resb 4096
PDT:             ; level 2 page table (Page Directory Table)
	resb 4096
PT:             ; level 1 page table (Page Table)
	resb 4096
stack_bottom:
	resb 16384  ; 16KB stack size
stack_top: 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; GDT implementation
;
; Reference: https://wiki.osdev.org/Global_Descriptor_Table
;            https://wiki.osdev.org/GDT_Tutorial
;            https://wiki.osdev.org/Setting_Up_Long_Mode
;            https://wiki.osdev.org/Task_State_Segment
;
; License: GPL-3.0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .rodata
GDT64:
    .null_segment: equ $ - GDT64
        dq 0

    .kernel_code_segment: equ $ - GDT64
        ; first 4 bytes, base + limit (NOTE: x86_64 use little endian, so the value placement is reversed)
        dw 0xffff  ; limit address = 0xffff + base address = 0x0000
		db 0       ; base = 0x00 (16 - 23)
        db 0x9a    ; access = 0x9a
                   ; |
                   ; +-> 0x9a = 0b10011010
                   ;     |-> P   = 1 (always set to 1)
                   ;     |-> DPL = 00 (CPU privilege level. 00 = highest(e.g. kernel), 11 = lowest (e.g. user app))
                   ;     |-> S   = 1 (define descriptor type. 0 = system segment (e.g. TSS), 1 = code / data segment)
                   ;     |-> E   = 1 (define executable bit. 0 = data segment, 1 = code segment which executed from)
                   ;     |-> DC  = 0 (define direction bit. 0 = segment grows up, 1 = otherwise)
                   ;     |-> RW  = 1 (define readable/writeable bit.
                   ;     |               for code segment, 0 = read in code segment is not allowed, 1 = otherwise
                   ;     |               for data segment, 0 = write in data segment is allowed, 1 = otherwise
                   ;     |           )
                   ;     +-> A   = 0 (define access. 0 = GDT stored in read-only pages.
                   ;                     However, it becomes 1 when CPU detects any page fault occured
                   ;                  )
				   ;
        db 0xaf    ; flags = 0xa , limit = 0xf
                   ;         |
				   ;         |-> G = 1 (0 = limit is 1 byte block, 1 = limit is 4KB block)
				   ;         |-> DB = 0 (0 = 16 bit protected mode segment, 1 = 32 bit protected mode segment)
				   ;         |-> L = 1 (1 = 64 bit code segment)
				   ;         +-> reserved
				   ;
		db 0       ; base = 0x00 (24 - 32)

    .kernel_data_segment: equ $ - GDT64
        dw 0xffff
        db 0
        db 0x92    ; acces = 0x92
        db 0xcf    ; flags = 0xc
		db 0

    .user_code_segment: equ $ - GDT64
        dw 0xffff
        db 0
        db 0xfa    ; access = 0xfa
        db 0xaf    ; flags = 0xa
		db 0

    .user_data_segment: equ $ - GDT64
        dw 0xffff
        db 0
        db 0xf2    ; access = 0xf2
        db 0xcf    ; flags = 0xc
		db 0

    .pointer:
        dw $ - GDT64 - 1
        dq GDT64

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
