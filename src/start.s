### start: program initialization and futures detection
	.global start, halt
	
	.section .boot, "ax", @progbits
start:
	## load page directory
	movl $pagedir, %ecx
	movl $VOFFSET, %edx
	subl %edx, %ecx
	movl %ecx, %cr3
	## enable 4MiB pages
	movl %cr4, %ecx
	or $0x00000010, %ecx
	movl %ecx, %cr4
	## enable paging
	movl %cr0, %ecx
	or $0x80000000, %ecx
	movl %ecx, %cr0
	## setup stack
	movl $stack_top, %esp
	push %ebx
	## go!
	jmp init

	.section .text
init:	
	call memmgr_init
	call vga_init
	call idt_init
	call i8259_init
	call atkbd_init
	call tests

halt:
	hlt
	jmp halt
