;;; start: program initialization and futures detection
	global start, halt
	
	extern memmgr_init
	extern vga_init
	extern idt_init
	extern i8259_init
	extern atkbd_init
	extern tests
	extern stack_top

	extern VOFFSET
	extern pagedir
	
	section .boot alloc exec progbits
start:
	;; load page directory
	mov ecx, pagedir
	mov edx, VOFFSET
	sub ecx, edx
	mov cr3, ecx
	;; enable 4MiB pages
	mov ecx, cr4
	or  ecx, 10h
	mov cr4, ecx
	;; enable paging
	mov ecx, cr0
	or  ecx, 80000000h
	mov cr0, ecx
	;; setup stack
	mov esp, stack_top
	push ebx
	;; go!
	jmp init

	section .text
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
