// Main of bootpack

#include <stdio.h>
#include "bootpack.h"

void HariMain(void)
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	char s[40], mcursor[256];
	int mx, my;

	init_gdtidt();
	init_pic();
	io_sti(); // Disable CPU interrupts because of IDT/PIC initialization is complete
	
	init_palette();  // Set pallete
	init_screen8(binfo->vram, binfo->scrnx, binfo->scrny);
	mx = (binfo->scrnx - 16) / 2; // Calculate coordinates to be in the center of the screen
	my = (binfo->scrny - 28 - 16) / 2;
	init_mouse_cursor8(mcursor, COL8_008484);
	putblock8_8(binfo->vram, binfo->scrnx, 16, 16, mx, my, mcursor, 16);
	sprintf(s, "(%d, %d)", mx, my);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, s);	

	io_out8(PIC0_IMR, 0xf9); // Allow PIC1 and keyboard(11111001)
	io_out8(PIC1_IMR, 0xef); // Allow mouse(11101111)

    for (;;) {
		io_hlt();
    }
}
