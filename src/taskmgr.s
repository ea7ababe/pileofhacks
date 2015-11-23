### taskmgr: task manager module
	.global taskmgr_init

	.section .text
taskmgr_init:
	push $13
	push $int13_handler
	ret
	
	## general protection fault handler
int13_handler:
	iret
