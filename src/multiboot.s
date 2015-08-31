### multiboot: the multiboot header
	.section .multiboot

	## multiboot magic number
	.set MAGIC,     0x1BADB002

	## multiboot header flags
	.set ALIGN,     1<<0
	.set MEMINFO,   1<<1
	.set VIDEOMODE, 1<<2

	.set FLAGS,     ALIGN | MEMINFO | VIDEOMODE
	.set CHECKSUM,  -(MAGIC + FLAGS)

	## video options
	.set MODE_TYPE, 1	# 0 for graphical mode, 1 for text
	.set WIDTH,     1024	# ignored in text mode
	.set HEIGHT,    600	# ignored ...
	.set DEPTH,     8	# ignored ...

	## His Majesty the Header
multiboot_header:	
	.long MAGIC
	.long FLAGS
	.long CHECKSUM
	.skip 20
	.long MODE_TYPE
	.long WIDTH
	.long HEIGHT
	.long DEPTH
