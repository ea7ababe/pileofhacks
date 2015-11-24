;;; taskmgr: task manager module
global taskmgr_init

extern idt_set

section .text
taskmgr_init:
	push 13
	push int13_handler
	call idt_set
	add  esp, 8
	ret
	
;; general protection fault handler
int13_handler:
	iret
