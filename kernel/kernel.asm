;
; kernel.asm
;
; License: GPL-3.0
;

global kernel_main

section .text
bits 64

; import functions in vga.asm
extern vga_write_char

kernel_main:
    ; Clean all registers
    mov rax, 0
    mov rbx, 0
    mov rcx, 0
    mov rdx, 0

    ; Print a character
    mov ax, 15           ; foreground
    mov bx, 0            ; background
    mov cx, 97           ; 'a' = 97
    call vga_write_char
    ret