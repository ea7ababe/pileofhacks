### idt: interrupt descriptor table control module
	.global idt_init
	.global idt_set, idt_unset

	.section .text
	
idt_init:
	lidt IDTH
	ret

	## (callback_ptr, int_no) -> IO
idt_set:
	mov 4(%esp), %eax
	mov 8(%esp), %ecx
	shl $3, %ecx
	add $IDT, %ecx
	movw %ax, (%ecx)
	movw $8, 2(%ecx)
	movw $0x8E00, 4(%ecx)
	shr $16, %eax
	mov %ax, 6(%ecx)
	ret

	## int_no -> IO
idt_unset:
	mov 4(%esp), %eax
	shl $3, %eax
	add $IDT, %eax
	movl $0, (%eax)
	movl $0, 4(%eax)
	ret

### Interrupt descriptor table
	## IDT header format
	## +0---15+16----31+ 6 byte
	## | size | offset |
	## +------+--------+

	## IDT entry format
       	## +0--------15+16----31+32--39+40-----------47+48--------63+ 8 byte
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

	## IDT header. In comparison with the GDT header it must be
	## placed before actual table (there is no null entry)
	.section .data
	.set idt_size, 8*256
IDTH:
	.short idt_size
	.long IDT
	
	.section .bss
IDT:
	.skip idt_size
