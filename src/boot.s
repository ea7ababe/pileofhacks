### Multiboot header
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
	
### Kernel stack
	.section .bss
stack_bottom:
	.skip 16384		# 16 KiB
stack_top:

### Start and end of the program
	.section .text
	.global start
start:
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

	//push %ebx
	call vga_test

halt:
	hlt
	jmp halt

### Multiboot information structure
	## bits name        presence
	## -------------------------
	## 0    flags       required
	## 4    mem_lower   if flags[0] is set
	## 8    mem_upper   if flags[0] is set
	## 12   boot_device if flags[1] is set
	## 16   cmdline     if flags[2] is set
	## 20   mods_count  if flags[3] is set
	## 24   mods_addr   if flags[3] is set
	## 28   syms        if flags[4] of flags[5] is set
	## 44   mmap_length if flags[6] is set
	## 48   mmap_addr   if flags[6] is set
	## -------------------------
	## 52:86 — other stuff (see multiboot specification)

	## flags contains information about available options
	## mem_lower contains available memory size below 1MiB in kilobytes (max 640kB(625KiB) ?_?)
	## mem_upper contains available memory size starting from 1MiB to the first gap
	## cmdline contains address to the program options 0-terminated string
	## mmap_length contains size of memory map buffer
	## mmap_addr contains address to memory map buffer

	## mmap entry:
	## bits name      description
	## 0    size      size of the entry
	## 4    base_addr base address of the memory region
	## 12   length    length of the memory region in bytes
	## 20   type      type of the memory region (1 for RAM)

	.section .text
parse_options:
	mov 4(%esp), %esi
	//todo//

### Memory manager
	.section .text
malloc:
	
free:	

### Test area
	.section .data
test_str_1:	
	.string "Test string!\n"
test_str_2:
	.string "Another test string.\n"
test_str_3:
	.string "Yet another test string.\n"
	
	.section .text
vga_test:
	call vga_text_init
	enter $16, $0
	movl $0, (%esp)
	.vga_test.loop:
	movl $test_str_1, (%esp)
	call vga_puts
	movl $test_str_2, (%esp)
	call vga_puts
	movl $test_str_3, (%esp)
	call vga_puts
	jmp .vga_test.loop
	leave
	ret
	
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
	.section .text
return:
	ret
	
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

	.global strlen
strlen:
	mov 4(%esp), %ecx
	xor %eax, %eax

	.strlen_next:
	mov (%ecx), %dl

	test %dl, %dl
	jz return
	inc %eax
	inc %ecx
	jmp .strlen_next

	.global memcpy
memcpy:
	mov 4(%esp), %edi
	mov 8(%esp), %esi
	mov 12(%esp), %ecx

	.memcpy_loop:
	test %ecx, %ecx
	jz return

	mov (%esi), %al
	mov %al, (%edi)
	inc %esi
	inc %edi
	dec %ecx
	jmp .memcpy_loop

### VGA driver
	.set VGA_TEXT_SCREEN, 0xB8000
	.set VGA_TEXT_WIDTH,  80*2
	.set VGA_TEXT_HEIGHT, 25
	.set VGA_TEXT_SCREEN_SIZE, 2*80*25

	.set VGA_TEXT_COLOR_BLACK, 0
	.set VGA_TEXT_COLOR_BLUE, 1
	.set VGA_TEXT_COLOR_GREEN, 2
	.set VGA_TEXT_COLOR_CYAN, 3
	.set VGA_TEXT_COLOR_RED, 4
	.set VGA_TEXT_COLOR_MAGENTA, 5
	.set VGA_TEXT_COLOR_BROWN, 6
	.set VGA_TEXT_COLOR_LIGHT_GREY, 7
	.set VGA_TEXT_COLOR_DARK_GREY, 8
	.set VGA_TEXT_COLOR_LIGHT_BLUE, 9
	.set VGA_TEXT_COLOR_LIGHT_GREEN, 10
	.set VGA_TEXT_COLOR_LIGHT_CYAN, 11
	.set VGA_TEXT_COLOR_LIGHT_RED, 12
	.set VGA_TEXT_COLOR_LIGHT_MAGENTA, 13
	.set VGA_TEXT_COLOR_LIGHT_BROWN, 14
	.set VGA_TEXT_COLOR_WHITE, 15

	.macro vga_make_entry char=' , fg=VGA_TEXT_COLOR_WHITE, bg=VGA_TEXT_COLOR_BLACK
	xor %ax, %ax
	mov $\bg, %ah
	shl $4, %ah
	mov $\fg, %ah
	mov $\char, %al
	.endm

	.macro vga_make_color fg=VGA_TEXT_COLOR_WHITE, bg=VGA_TEXT_COLOR_BLACK
	xor %ah, %ah
	mov $\bg, %ah
	shl $4, %ah
	mov $\fg, %ah
	.endm

	.section .bss
vga_text_cursor_position:
	.skip 4
vga_text_screen_color:
	.skip 1
vga_text_buffer:
	.skip VGA_TEXT_SCREEN_SIZE

	.section .text
	.global vga_text_init
vga_text_init:
	movl $0, vga_text_cursor_position
	xor %ah, %ah
	mov $VGA_TEXT_COLOR_BLACK, %ah
	shl $4, %ah
	mov $VGA_TEXT_COLOR_WHITE, %ah
	mov %ah, vga_text_screen_color
	call vga_text_clear
	call vga_text_flush
	ret

	.global vga_text_clear
vga_text_clear:
	mov $VGA_TEXT_SCREEN_SIZE, %ecx
	mov vga_text_screen_color, %ah
	mov $' , %al
	.vga_text_clear.loop:
	sub $2, %ecx
	mov %ax, vga_text_buffer(%ecx)
	jnz .vga_text_clear.loop
	ret
	
	.global vga_text_flush
vga_text_flush:
	push $VGA_TEXT_SCREEN_SIZE
	push $vga_text_buffer
	push $VGA_TEXT_SCREEN
	call memcpy
	add $12, %esp
	ret

	.global vga_putc
vga_putc:
	mov 4(%esp), %ecx
	mov vga_text_screen_color, %ch
	mov vga_text_cursor_position, %esi
	
	cmp $'\n, %cl
	je .vga_putc.new_line

	mov %cx, vga_text_buffer(%esi)
	add $2, %esi
	jmp .vga_putc.test_eos

	.vga_putc.new_line:
	mov %esi, %eax
	xor %edx, %edx
	mov $VGA_TEXT_WIDTH, %edi
	idiv %edi
	sub %edx, %edi
	add %edi, %esi

	.vga_putc.test_eos:
	cmp $VGA_TEXT_SCREEN_SIZE, %esi
	je .vga_putc.scroll
	mov %esi, vga_text_cursor_position
	ret

	.vga_putc.scroll:
	mov $VGA_TEXT_WIDTH, %eax
	.vga_putc.scroll.copy:
	mov vga_text_buffer(%eax), %dx
	mov %dx, vga_text_buffer-VGA_TEXT_WIDTH(%eax)
	add $2, %eax
	cmp $VGA_TEXT_SCREEN_SIZE, %eax
	jne .vga_putc.scroll.copy
	
	mov vga_text_screen_color, %dh
	mov $' , %dl
	.vga_putc.scroll.clear:
	sub $2, %eax
	mov %dx, vga_text_buffer(%eax)
	cmp $VGA_TEXT_SCREEN_SIZE-VGA_TEXT_WIDTH, %eax
	jne .vga_putc.scroll.clear
	
	mov %eax, vga_text_cursor_position
	ret

	.global vga_putchar
vga_putchar:
	mov 4(%esp), %eax
	push %eax
	call vga_putc
	add $4, %esp
	call vga_text_flush
	ret

	.global vga_puts
vga_puts:
	mov 4(%esp), %esi
	enter $8, $0
	movl $0, (%esp)

	.vga_puts.loop:
	mov (%esi), %al
	inc %esi
	test %al, %al
	jz .vga_puts.return

	mov %esi, 4(%esp)
	mov %al, (%esp)
	call vga_putc
	mov 4(%esp), %esi
	jmp .vga_puts.loop

	.vga_puts.return:
	call vga_text_flush
	leave
	ret
	
### PIC
	.set MPICC, 0x20	# master pic command port
	.set MPICD, 0x21	# master, data
	.set SPICC, 0xA0	# slave, command
	.set SPICD, 0xA1	# slave, data
	.set EOI, 0x20		# end of interrupt command

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

	.section .data
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

### Page directory
	## page directory entry format
	## +31-------------12+11----9+8---------------0+
	## |page table offset|ignored|G|S|0|A|D|W|U|R|P|
	## +--------20-------+---3---+--------9--------+
	##
	## G - translation is global. Just ignore...
	## S - page size: if set than page is 4MB, otherwise it is 4KB.
	## A - accessed: this bit is set by the CPU when the page is accessed.
	## D - cache disable bit: if set the page will not be cached.
	## W - write-through: if the bit is set, write-through caching is enabled
	##                    if not, then write-back is enabled instead.
	## U - user bit: if set, then the page can be accessed by all
	##               otherwise only supervisor can access it.
	## R - read/write: if set, the page is read/write, otherwise it is read-only
	## P - present: the page is in physical memory
	##              if the page, for example, swaped out, it is not present.
	
	.section .bss
PD:
	.skip 4096

### Page tables
	## page table entry format
	## +31----------------12+11----9+8---------------0+
	## |physical page offset|ignored|G|0|D|A|C|W|U|R|P|
	## +---------20---------+---3---+--------9--------+
	##
	## G - global flag: prevents TLB from updating the address in it's cache if CR3 is reset
	##                  the page global enable bit in CR4 must be set to enable this feature
	## D - dirty flag: if set, then the page has been written to
	##                 this flag is not updated by the CPU, and once set will not unset itself
