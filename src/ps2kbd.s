### ps2kbd: PS/2 keyboard module
	.global ps2kbd_init

	.include "def/i8259.s"

	.set PS2D, 0x60
	.set PS2C, 0x64
	.set PS2V, 0x1

	.section .text
ps2kbd_init:
	push $MPICV+PS2V
	push $ps2kbd_isr
	call idt_set
	movl $PS2V, (%esp)
	call i8259_unmask
	add $8, %esp
	ret
	
ps2kbd_isr:
	push $test_msg
	call vga_puts
	add $4, %esp
	mov $PIC_EOI, %al
	out %al, $MPICC
	out %al, $SPICC
	iret

	.section .data
test_msg:
	.string "Key pressed!\n"
