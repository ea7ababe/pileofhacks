;;; memmgr: memory management module
	global stack_bottom, stack_top
	global pagedir
	global memmgr_init

	section .text
memmgr_init:
	lgdt [GDT]
	jmp 8:.reload_cs
	.reload_cs:
	mov eax, 16
	mov ds, eax
	mov ss, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	ret

;;; Kernel call stack
	section .call_stack alloc write nobits
stack_bottom:
	resb 4000h		; 16KiB
stack_top:
	
;;; Global descriptor table
	;; GDT header format
	;; +0---15+16----31+ 6 bytes
	;; | size | offset |
	;; +------+--------+

	;; GDT entry format
	;; +0-------15+16-----31+32------39+40-------47+48-------51+52-55+56------63+ 8 bytes
	;; |limit 0:15|base 0:15|base 16:23|access byte|limit 16:19|flags|base 24:31|
	;; +----------+---------+----------+-----------+-----------+-----+----------+
	;;     	16     	   16  	      8	       	 8     	     4 	      4	       8

	;; GDT entry access byte
	GDT_Pr equ 0b10000000	; present bit
	GDT_P1 equ 0b00100000	; privilege level 1
	GDT_P2 equ 0b01000000	; privilege level 2
	GDT_P3 equ 0b01100000	; privilege level 3
	GDT_Dt equ 0b00010000	; descriptor type (0 = system, 1 = code/data)
	GDT_Ex equ 0b00001000	; executable bit
	GDT_Dn equ 0b00000100	; Ex=0: direction bit
				; (segment grows down: the offset has to be larger than limit)
	GDT_Cf equ 0b00000100	; Ex=1: confirming bit
				; (code can be executed from lower privilege level)
	GDT_W  equ 0b00000010	; Ex=0: data segment is writable
	GDT_R  equ 0b00000010	; Ex=1: executable segment is readable
	GDT_Ac equ 0b00000001	; access bit ?_?

	;; GDT entry flags
	GDT_Gr equ 0b10000000	; granularity bit
				; if 0 the "limit" field is in 1B blocks
				; if 1 the "limit" field is in 4kB blocks
	GDT_Sz equ 0b01000000	; size bit (1 for 32 bit mode, 0 for 16 bit mode)
				; it defines the size of the stack cells

	section .data
GDT:
	;; header (null entry)
	dw gdt_size
	dd GDT
	dw 0
	;; supervisor code segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_Ex | GDT_R
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	;; supervisor data segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_W
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	;; user code segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_Ex | GDT_R | GDT_P3
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	;; user data segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_W | GDT_P3
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	;; GDT end
	gdt_size equ $-GDT-1

	;; task state segment entry format
	;; +0-15+16----31+32-63+64-79+80-95+96-127+128-143+144--159+160--191+
	;; |LINK|RESERVED|ESP0 |SS0  |RSRVD|ESP1  |SS1    |RESERVED|ESP2    |
	;; +----+--------+-----+-----+-----+------+-------+--------+--------+
	;; +192-207+208--223+224-255+256-287+288-319+320-351+352-383+384-415+
	;; |SS2    |RESERVED|CR3    |EIP    |EFLAGS |EAX    |ECX    |EDX    |
	;; +-------+--------+-------+-------+-------+-------+-------+-------+
	;; +416-447+448-479+480-511+512-543+544-575+576-591+592--607+608-623+
	;; |EBX    |ESP    |EBP    |ESI    |EDI    |ES     |RESERVED|CS     |
	;; +-------+-------+-------+-------+-------+-------+--------+-------+
	;; +624--639+640-655+656--671+672-687+688--703+704-719+720-------735+
	;; |RESERVED|SS     |RESERVED|DS     |RESERVED|FS     |RESERVED     |
	;; +--------+-------+--------+-------+--------+-------+-------------+
	;; +736-751+752--767+768-783+784--815+816-----831+
	;; |GS     |RESERVED|LDTR   |RESERVED|IOBP offset| 104 bytes
	;; +-------+--------+-------+--------+-----------+

TSS0:
	dd 1, 2
	TSS0_size equ $-TSS0
	
;;; Page directory
	;; page directory entry format
	;; +31-------------12+11----9+8---------------0+
	;; |page table offset|ignored|G|S|0|A|D|W|U|R|P|
	;; +--------20-------+---3---+--------9--------+
	;;
	;; G - translation is global. Just ignore...
	;; S - page size: if set than page is 4MB, otherwise it is 4KB.
	;; A - accessed: this bit is set by the CPU when the page is accessed.
	;; D - cache disable bit: if set the page will not be cached.
	;; W - write-through: if the bit is set, write-through caching is enabled
	;;                    if not, then write-back is enabled instead.
	;; U - user bit: if set, then the page can be accessed by all
	;;               otherwise only supervisor can access it.
	;; R - read/write: if set, the page is read/write, otherwise it is read-only
	;; P - present: the page is in physical memory
	;;              if the page, for example, swaped out, it is not present.
	
	;; page table entry format
	;; +31----------------12+11----9+8---------------0+
	;; |physical page offset|ignored|G|0|D|A|C|W|U|R|P|
	;; +---------20---------+---3---+--------9--------+
	;;
	;; G - global flag: prevents TLB from updating the address in it's cache if CR3 is reset
	;;                  the page global enable bit in CR4 must be set to enable this feature
	;; D - dirty flag: if set, then the page has been written to
	;;                 this flag is not updated by the CPU, and once set will not unset itself

	VADDRSPACE equ 0xC0000000
	BASEPAGE equ (0xC0000000 >> 22)
	
section .data
align 0x1000
pagedir:
	dd 0x00000083	; temporary page for boot section
	times (BASEPAGE-1)*4 db 0
	dd 0x00000083	; program base page
	times (1024-BASEPAGE-1)*4 db 0
