### tests module
	.global tests

tests:
	push $0x47
	push $test_isr
	call idt_set
	int $0x47
	int $0x21
	add $8, %esp
	ret

test_isr:
	push $test_str
	call vga_puts
	add $4, %esp
	iret

	.section .data
test_str:
	.string "Testing...\n"
