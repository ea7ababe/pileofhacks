### Multiboot header
	.section .multiboot
	.align 4

	## multiboot magic number
	.set MAGIC,    0x1BADB002

	## multiboot header flags
	.set ALIGN,    1<<0
	.set MEMINFO,  1<<1
	.set VIDEOMODE,1<<2

	.set FLAGS,    ALIGN | MEMINFO | VIDEOMODE
	.set CHECKSUM, -(MAGIC + FLAGS)

	## video options
	.set MODE_TYPE, 1	# 0 for graphical mode, 1 for text
	.set WIDTH, 1024	# ignored in text mode
	.set HEIGHT, 600	# ignored ...
	.set DEPTH, 8		# ignored ...

	## His Majesty the Header
	.long MAGIC
	.long FLAGS
	.long CHECKSUM
	.skip 20
	.long MODE_TYPE
	.long WIDTH
	.long HEIGHT
	.long DEPTH

### Code segment
	.section .text

### Start and end of the program
	.global _start
_start:
	movl $stack_top, %esp
	lgdt GDT

	jmp $8, $.reload_cs
	.reload_cs:
	mov $16, %eax
	mov %eax, %ds
	mov %eax, %es
	mov %eax, %fs
	mov %eax, %gs
	mov %eax, %ss

	lidt IDTH

	push %ebx
	call main

_end:
	hlt
	jmp _end

### Test area
test_interrupt:
	mov $smile_isr, %eax
	mov %ax, IDT+49*8
	movw $8, IDT+49*8+2
	movw $0x8E00, IDT+49*8+4
	shr $16, %eax
	mov %ax, IDT+49*8+6
	int $49
	ret
	
smile_isr:
	push $0x61
	call vga_putchar
	add $4, %esp
	iret

### Misc
	.global int2str
int2str:
	mov 4(%esp), %eax
	mov 8(%esp), %esi
	add $10, %esi
	movb $0, (%esi)
	dec %esi
	xor %edx, %edx
	mov $10, %ecx
	
	.int2str_cond:
	cmp %eax, %ecx
	jg .int2str_end
	
	idiv %ecx
	add $0x30, %edx
	mov %dl, (%esi)
	xor %edx, %edx
	dec %esi
	jmp .int2str_cond

	.int2str_end:
	add $0x30, %eax
	mov %al, (%esi)
	mov %esi, %eax
	ret

### Data segment
	.section .data

### Global descriptor table
	## GDT header format
	## +0---15+16----31+ 6 byte
	## | size | offset |
	## +------+--------+

	## GDT entry format
	## +0-------15+16-----31+32------39+40-------47+48-------51+52-55+56------63+ 8 byte
	## |limit 0:15|base 0:15|base 16:23|access byte|limit 16:19|flags|base 24:31|
	## +----------+---------+----------+-----------+-----------+-----+----------+
	##     	16     	   16  	      8	       	 8     	     4 	      4	       8

	## GDT entry access byte
	.set GDT_Pr, 0b10010000	# present bit and... another bit
	.set GDT_P1, 0b00100000	# privilege level 1
	.set GDT_P2, 0b01000000	# privilege level 2
	.set GDT_P3, 0b01100000	# privilege level 3
	.set GDT_Ex, 0b00001000	# executable bit
	.set GDT_Dn, 0b00000100	# Ex=0: direction bit
				# (segment grows down: the offset has to be larger than limit)
	.set GDT_Cf, 0b00000100	# Ex=1: confirming bit
				# (code can be executed from lower privilege level)
	.set GDT_W,  0b00000010	# Ex=0: data segment is writable
	.set GDT_R,  0b00000010	# Ex=1: executable segment is readable
	.set GDT_Ac, 0b00000001	# access bit ?_? never used it...

	## GDT entry flags
	.set GDT_Gr, 0b10000000	# granularity bit
				# if 0 the "limit" field is in 1B blocks
				# if 1 the "limit" field is in 4kB blocks
	.set GDT_Sz, 0b01000000	# size bit (1 for 32 bit mode, 0 for 16 bit mode)
				# it defines the size of the stack cells

	.global GDT, gdt_size
GDT:
	## header (null entry)
	.short gdt_size
	.long GDT
	.skip 2
	## code segment entry
	.short 0xffff
	.short 0x0
	.byte  0x0
	.byte  GDT_Pr | GDT_Ex | GDT_R
	.byte  0xf | GDT_Sz | GDT_Gr
	.byte  0x0
	## data segment entry
	.short 0xffff
	.short 0x0
	.byte  0x0
	.byte  GDT_Pr | GDT_W
	.byte  0xf | GDT_Sz | GDT_Gr
	.byte  0x0
	## GDT end
	gdt_size = . - GDT - 1

### Interrupt descriptor table
	## IDT header format
	## +0---15+16----31+ 6 byte
	## | size | offset |
	## +------+--------+

	## IDT entry format
       	## +0--------15+16----31+32--39+40-----------47+48--------63+
	## |offset 0:15|selector| zero |type/attributes|offset 16:31|
       	## +-----16----+---16---+---8--+-------8-------+-----16-----+

	## IDT entry type/attributes byte
	.set IDT_Pr, 0b10000000	# present bit
	.set IDT_P1, 0b00100000	# privilege level 1
	.set IDT_P2, 0b01000000	# privilege level 2
	.set IDT_P3, 0b01100000	# privilege level 3
	.set IDT_TaG, 0b0000101	# gate types : task gate
	.set IDT_Int16, 0b00110	#              16-bit interrupt gate
	.set IDT_TrG16, 0b00111	#              16-bit trap gate
	.set IDT_Int32, 0b01110	#              32-bit interrupt gate
	.set IDT_TrG16, 0b01111	#              32-bit trap gate

	.global IDTH, IDT, idt_size
	## IDT header. In comparison with the GDT header it must be
	## placed before actual table (there is no null entry)
IDTH:
	.short idt_size
	.long IDT
IDT:
	.skip 8*256
	idt_size = . - IDT - 1

### Kernel stack
	.section .bootstrap_stack, "aw", @nobits
stack_bottom:
	.skip 16384		# 16 KiB
stack_top:

	program_end = .
