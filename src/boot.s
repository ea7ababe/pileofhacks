	.set ALIGN,    1<<0
	.set MEMINFO,  1<<1
	.set VIDEOMODE,1<<2
	.set FLAGS,    ALIGN | MEMINFO | VIDEOMODE
	.set MAGIC,    0x1BADB002
	.set CHECKSUM, -(MAGIC + FLAGS)
	.set MODE_TYPE, 1
	.set WIDTH, 1024
	.set HEIGHT, 600
	.set DEPTH, 8

.section .multiboot
.align 4
	.long MAGIC
	.long FLAGS
	.long CHECKSUM
	.skip 20
	.long MODE_TYPE
	.long WIDTH
	.long HEIGHT
	.long DEPTH

.section .bootstrap_stack, "aw", @nobits
stack_bottom:
	.skip 16384 # 16 KiB
stack_top:

.section .text
.global _start
.type _start, @function
_start:
	movl $stack_top, %esp
	call kernel_main

	cli
.Lhang:
	hlt
	jmp .Lhang

