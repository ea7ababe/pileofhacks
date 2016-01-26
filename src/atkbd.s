;;; atkbd: PS/2 keyboard module
global atkbd_init

extern idt_set
extern i8259_unmask
extern vga_puts

%include "def/i8259.s"

	PS2D equ 60h
	PS2C equ 64h
	PS2V equ  1h

section .text
atkbd_init:
	push MPICV+PS2V
	push atkbd_isr
	call idt_set
	mov  long [esp], PS2V
	call i8259_unmask
	add  esp, 8
	ret
	
atkbd_isr:
	in   al, PS2D
	push test_msg
	call vga_puts
	add  esp, 4
	mov  al, PIC_EOI
	out  MPICC, al
	out  SPICC, al
	iret

section .data
test_msg:
	db `Key pressed!\n`
