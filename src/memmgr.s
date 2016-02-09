;;; memmgr: memory management module
global pagedir

	VADDRSPACE equ 0xC0000000
	BASEPAGE equ (VADDRSPACE >> 22)
	
