ENTRY (_start)

SECTIONS {
	. = 2M;

	.text : {
		. = ALIGN(16);           /* 16 bytes boundary */
		KEEP(*( .multiboot2 ))
		*(.text)
	}

	.rodata : {
		*(.rodata)
	}

	.data : {
		*(.data)
	}

	.bss : {
		*(.bss)
	}
}