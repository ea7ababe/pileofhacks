;;; tests module
global tests

extern idt_set
extern vga_puts
extern get_free_paper
extern return_page

tests:
	push 0x47
	push test_isr
	call idt_set
	int 0x47
	
	add esp, 8
	ret

test_isr:
	push test_str
	call vga_puts
	add  esp, 4
	iret

section .data
test_str:
	db `Testing...\n`
