;
; gdt.asm
;
; Reference: https://wiki.osdev.org/Global_Descriptor_Table
;            https://wiki.osdev.org/GDT_Tutorial
;            https://wiki.osdev.org/Setting_Up_Long_Mode
;
; License: GPL-3.0
;

section .rodata
GDT:
    .null_segment:
        dq 0
    .kernel_code_segment:
    .kernel_data_segemnt:
    .user_code_segment:
    .user_data_segment: