### start: program initialization and futures detection
	.global start, halt
	
	.section .text
start:
	movl $stack_top, %esp
	push %ebx
	call memmgr_init
	call vga_init
	call idt_init
	call i8259_init
	call ps2kbd_init
	call tests
	
halt:
	hlt
	jmp halt
