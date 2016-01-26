;;; memmgr: memory management module
global pagedir
global memmgr_init

;;; Task state segment (already forgot why were I need it)
	; task state segment entry format
	; +0-15+16----31+32-63+64-79+80-95+96-127+128-143+144--159+160--191+
	; |LINK|RESERVED|ESP0 |SS0  |RSRVD|ESP1  |SS1    |RESERVED|ESP2    |
	; +----+--------+-----+-----+-----+------+-------+--------+--------+
	; +192-207+208--223+224-255+256-287+288-319+320-351+352-383+384-415+
	; |SS2    |RESERVED|CR3    |EIP    |EFLAGS |EAX    |ECX    |EDX    |
	; +-------+--------+-------+-------+-------+-------+-------+-------+
	; +416-447+448-479+480-511+512-543+544-575+576-591+592--607+608-623+
	; |EBX    |ESP    |EBP    |ESI    |EDI    |ES     |RESERVED|CS     |
	; +-------+-------+-------+-------+-------+-------+--------+-------+
	; +624--639+640-655+656--671+672-687+688--703+704-719+720-------735+
	; |RESERVED|SS     |RESERVED|DS     |RESERVED|FS     |RESERVED     |
	; +--------+-------+--------+-------+--------+-------+-------------+
	; +736-751+752--767+768-783+784--815+816-----831+
	; |GS     |RESERVED|LDTR   |RESERVED|IOBP offset| 104 bytes
	; +-------+--------+-------+--------+-----------+

section .data
TSS0:
	dd 1, 2
	TSS0_size equ $-TSS0
	
;;; Page directory and page tables
	; page directory entry format
	; +31-------------12+11----9+8---------------0+
	; |page table offset|ignored|G|S|0|A|D|W|U|R|P|
	; +--------20-------+---3---+--------9--------+
	;
	; G - translation is global. Just ignore...
	; S - page size: if set than page is 4MB, otherwise it is 4KB.
	; A - accessed: this bit is set by the CPU when the page is accessed.
	; D - cache disable bit: if set the page will not be cached.
	; W - write-through: if the bit is set, write-through caching is enabled
	;                    if not, then write-back is enabled instead.
	; U - user bit: if set, then the page can be accessed by all
	;               otherwise only supervisor can access it.
	; R - read/write: if set, the page is read/write, otherwise it is read-only
	; P - present: the page is in physical memory
	;              if the page, for example, swaped out, it is not present.
	
	; page table entry format
	; +31----------------12+11----9+8---------------0+
	; |physical page offset|ignored|G|0|D|A|C|W|U|R|P|
	; +---------20---------+---3---+--------9--------+
	;
	; G - global flag: prevents TLB from updating the address in it's cache if CR3 is reset
	;                  the page global enable bit in CR4 must be set to enable this feature
	; D - dirty flag: if set, then the page has been written to
	;                 this flag is not updated by the CPU, and once set will not unset itself

	VADDRSPACE equ 0xC0000000
	BASEPAGE equ (VADDRSPACE >> 22)
	
section .data
align 0x1000
pagedir:
	dd 0x83			; temporary page for boot section
	times BASEPAGE-1 dd 0
	dd 0x83			; program base page
	times 1024-BASEPAGE-1 dd 0

;; Page allocator
section .text
palloc:

