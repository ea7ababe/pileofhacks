;;; tests module
global tests

%include "def/alloc.s"
%include "def/apic.s"
%include "def/i8259.s"

extern idt_set
extern vga_puts
extern get_free_paper
extern return_page
extern move_your_ass
extern allot

tests:
	enter 32, 0

        mov long [esp], 16777216
        call move_your_ass

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
