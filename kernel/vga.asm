;
; vga.asm
;
; Reference: https://www.nasm.us/doc/nasmdoc4.html
;            https://wiki.osdev.org/Printing_To_Screen
;
; License: GPL-3.0
;

; Make functions available globally
global vga_write_char

section .text
;
; vga_write_char(eax = 4-bit foreground, ebx = 4-bit background, ecx = 8-bit character, edx = 32-bit vga address)
;
; [0xb8000] = background + foreground + character
;
vga_write_char:
    shl ax, 8
    shl bx, 12
    or ax, bx
    or ax, cx
    mov word [0xb8000], ax
    ret