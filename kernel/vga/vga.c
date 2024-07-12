#include "vga.h"

// VGA constants
#define VGA_ADDR 0xB8000

#define VGA_HEIGHT 50
#define VGA_WIDTH 160

#define VGA_COLOR_BLACK 0
#define VGA_COLOR_BLUE 1
#define VGA_COLOR_GREEN 2
#define VGA_COLOR_CYAN 3
#define VGA_COLOR_RED 4
#define VGA_COLOR_MAGENTA 5
#define VGA_COLOR_BROWN 6
#define VGA_COLOR_LIGHT_GREY 7
#define VGA_COLOR_DARK_GREY 8
#define VGA_COLOR_LIGHT_BLUE 9
#define VGA_COLOR_LIGHT_GREEN 10
#define VGA_COLOR_LIGH_CYAN 11
#define VGA_COLOR_LIGHT_RED 12
#define VGA_COLOR_LIGHT_MAGENTA 13
#define VGA_COLOR_LIGHT_BROWN 14
#define VGA_COLOR_WHITE 15

// VGA setup
const uint16_t vga_height = (uint16_t) VGA_HEIGHT;
const uint16_t vga_width = (uint16_t) VGA_WIDTH;
uint16_t* vga_buffer = (uint16_t*) VGA_ADDR;

uint16_t row = 0;
uint16_t column = 0;
const uint16_t default_color = (VGA_COLOR_GREEN << 8) | (VGA_COLOR_BLACK << 12); // foreground | background
uint16_t current_color = default_color;

// Implementations
void vga_clear_screen(void) {
	row = 0;
	column = 0;
	current_color = default_color;
	vga_buffer = (uint16_t*) VGA_ADDR;

	for (uint16_t y=0; y<vga_height; y++) {
		for (uint16_t x=0; x<vga_width; x++) {
			vga_buffer[y * vga_width + x] = ' ' | default_color;
		}
	}
}

void vga_scroll_up(void) {
	for (uint16_t y=0; y<vga_height; y++) {
		for (uint16_t x=0; x<vga_width; x++) {
			vga_buffer[(y-1) * vga_width + x] = vga_buffer[y * vga_width + x];
		}
	}


	for (uint16_t x=0; x<vga_width; x++) {
		vga_buffer[(vga_height-1) * vga_width + x] = ' ' | current_color;
	}
}

void vga_write_char(char data) {
	// Cases for escape sequences
	switch (data) {
		case '\n':
			new_line();
			break;
		case '\r':
			column = 0;
			break;
		default:
			if (column == vga_width) {
				new_line();
			}
			vga_buffer[row * vga_width + column] = data | current_color;
			break;
	}

	if (++column == vga_width) {
		column = 0;
		if (++row == vga_height) {
			row = 0;
		}
	}
}

void vga_write_string(const char *data, uint64_t size) {
	for (uint64_t i=0; i<size; i++) {
		if (data[i] == '\0') {
			break;
		} else {
			vga_write_char(data[i]);
		}
	}
}

// Additional method (as helper) for this module
void new_line(void) {
    if (row < vga_height - 1) {
		row++;
		column = 0;
	} else {
		vga_scroll_up();
		column = 0;
	}
}