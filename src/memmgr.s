### memmgr: memory management module
	.global stack_bottom, stack_top
	.global memmgr_init	

	.section .text
memmgr_init:
	lgdt GDT
	jmp $8, $memmgr_init.reload_cs
	memmgr_init.reload_cs:
	mov $16, %eax
	mov %eax, %ds
	mov %eax, %ss
	mov %eax, %es
	mov %eax, %fs
	mov %eax, %gs
	ret

### Kernel call stack
	.section .call_stack, "aw", @nobits
stack_bottom:
	.skip 0x4000		# 16KiB
stack_top:
	
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
	
	## page table entry format
	## +31----------------12+11----9+8---------------0+
	## |physical page offset|ignored|G|0|D|A|C|W|U|R|P|
	## +---------20---------+---3---+--------9--------+
	##
	## G - global flag: prevents TLB from updating the address in it's cache if CR3 is reset
	##                  the page global enable bit in CR4 must be set to enable this feature
	## D - dirty flag: if set, then the page has been written to
	##                 this flag is not updated by the CPU, and once set will not unset itself
	
	.section .bss
PD:
	.skip 4096
