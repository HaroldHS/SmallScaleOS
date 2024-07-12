#include "vga/vga.h"

void kernel_main() {
    vga_clear_screen();
    vga_write_string("Welcome to SmallScaleOS\r\n", 26);
    return;
}