;;; Here lies the multiboot header
global multiboot_info

;; multiboot magic number
%define MAGIC     0x1BADB002

;; multiboot header flags
;; align & meminfo & videomode
%define FLAGS     ((1<<0) | (1<<1) | (1<<2))
%define CHECKSUM  -(MAGIC + FLAGS)

;; video options
%define MODE_TYPE 1	; 0 for graphical mode, 1 for text
%define WIDTH     0	; ignored in text mode
%define HEIGHT    0	; ignored ...
%define DEPTH     0	; ignored ...

;; His Majesty the Header
section .multiboot
multiboot_header:	
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
	times 20 db 0
	dd MODE_TYPE
	dd WIDTH
	dd HEIGHT
	dd DEPTH

section .bss
multiboot_info:
	resd 1
