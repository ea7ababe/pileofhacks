;;; multiboot: the multiboot header
	section .multiboot

	; multiboot magic number
	MAGIC       equ 1BADB002h

	; multiboot header flags
	; align & meminfo & videomode
	FLAGS       equ (1<<0) | (1<<1) | (1<<2)
	CHECKSUM    equ -(MAGIC + FLAGS)

	;; video options
	MODE_TYPE   equ 1	; 0 for graphical mode, 1 for text
	WIDTH       equ 1024	; ignored in text mode
	HEIGHT      equ 600	; ignored ...
	DEPTH       equ 8	; ignored ...

	;; His Majesty the Header
multiboot_header:	
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
	times 20 db 0
	dd MODE_TYPE
	dd WIDTH
	dd HEIGHT
	dd DEPTH
