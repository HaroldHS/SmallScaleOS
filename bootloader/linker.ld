ENTRY (_start)

SECTIONS {

	. = 1M;

	.boot : {
		KEEP(*(.multiboot2))
	}

	.text : {
		*(.text)
	}

	.rodata : {
		*(.rodata)
	}

	.data : {
		*(.data)
	}

	.bss : {
		*(COMMON)
		*(.bss)
	}
}