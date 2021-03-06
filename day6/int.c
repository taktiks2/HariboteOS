// Interrupt

#include "bootpack.h"

void init_pic(void)
// Initialize PIC
{
	io_out8(PIC0_IMR,  0xff  ); // Do not accept all interrupts
	io_out8(PIC1_IMR,  0xff  ); // Do not accept all interrupts
	
	io_out8(PIC0_ICW1, 0x11  ); // Edge trigger mode           
	io_out8(PIC0_ICW2, 0x20  ); // IRQ0-7 is received by INT20-27
	io_out8(PIC0_ICW3, 1 << 2); // PIC1 is connected at IRW2   
	io_out8(PIC0_ICW4, 0x01  ); // Non-buffer mode             

	io_out8(PIC1_ICW1, 0x11  ); // Edge trigger mode           
	io_out8(PIC1_ICW2, 0x28  ); // IRQ8-15 is received by INT28-2f
	io_out8(PIC1_ICW3, 2     ); // PIC1 is connected at IRW2   
	io_out8(PIC1_ICW4, 0x01  ); // Non-buffer mode             

	io_out8(PIC0_IMR,  0xfb  ); // Do not accept all interrupts
	io_out8(PIC1_IMR,  0xff  ); // Do not accept all interrupts

	return;
}

void inthandler21(int *esp)
// Interrupt from PS/2 keyboard
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 21 (IRQ-1) : PS/2 keyboard");
	for (;;) {
		io_hlt();
	}
}

void inthandler2c(int *esp)
// Interrupt from PS/2 mouse
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 2C (IRQ-12) : PS/2 mouse");
	for (;;) {
		io_hlt();
	}
}

void inthandler27(int *esp)
// Measures against incomplete interrupt from PIC0
{
	io_out8(PIC0_OCW2, 0x67); // Notify PIC that IRQ-07 reception has been completed
	return;
}
