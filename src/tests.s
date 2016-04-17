;;; tests module
global tests

%include "def/memmgr.s"
%include "def/apic.s"
%include "def/i8259.s"

extern idt_set
extern vga_puts
extern allot

tests:
	enter 32, 0

        ; tests here

	leave
	ret

test_isr:
	push test_str
	call vga_puts
	add  esp, 4
	iret

test_i8259_isr:
        push test_str
        call vga_puts
        add esp, 4
        i8259_eoi
        iret

section .data
test_str:
	db `.`
