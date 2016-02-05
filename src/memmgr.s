;;; memmgr: memory management module
global pagedir

	VADDRSPACE equ 0xC0000000
	BASEPAGE equ (VADDRSPACE >> 22)
	
section .data
align 0x1000
pagedir:
	dd 0x83			; temporary page for boot section
	times BASEPAGE-1 dd 0
	dd 0x83			; program base page
	times 1024-BASEPAGE-1 dd 0
