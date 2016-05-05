;;; atkbd: PS/2 keyboard module
global atkbd_init

extern idt_set
extern i8259_unmask
extern putchar
extern itoa

%include "def/i8259.s"

%define PS2D 60h
%define PS2C 64h
%define PS2V  1h

section .text
atkbd_init:
	push MPICV+PS2V
	push atkbd_isr
	call idt_set
	mov  long [esp], PS2V
	call i8259_unmask
	add  esp, 8
	ret

;; here will be a keyboard driver :)
atkbd_isr:
	in  al, PS2D
        cmp al, 28
        je .enter
        push '.'
        call putchar
        jmp .ret
.enter:
        push `\n`
        call putchar

.ret:
        add esp, 4
	mov  al, PIC_EOI
	out  MPICC, al
	out  SPICC, al
	iret
