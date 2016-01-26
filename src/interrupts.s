;;; idt: interrupt descriptor table control module
global idt_init
global idt_set, idt_unset

section .text
idt_init:
	lidt [IDTH]
	ret

	; (callback_ptr, int_no) -> IO
idt_set:
	mov eax, [esp+4]
	mov ecx, [esp+8]
	shl ecx, 3
	add ecx, IDT
	mov word [ecx], ax
	mov word [ecx+2], 8
	mov word [ecx+4], 0x8E00
	shr eax, 16
	mov [ecx+6], ax
	ret

	; int_no -> IO
idt_unset:
	mov eax, [esp+4]
	shl eax, 3
	add eax, IDT
	mov long [eax], 0
	mov long [eax+4], 0
	ret

;; Interrupt descriptor table
	; IDT header format
	; +0---15+16----31+ 6 byte
	; | size | offset |
	; +------+--------+

	; IDT entry format
       	; +0--------15+16----31+32--39+40-----------47+48--------63+ 8 byte
	; |offset 0:15|selector| zero |type/attributes|offset 16:31|
       	; +-----16----+---16---+---8--+-------8-------+-----16-----+

	; IDT entry type/attributes byte
	IDT_Pr equ 0b10000000	; present bit
	IDT_P1 equ 0b00100000	; privilege level 1
	IDT_P2 equ 0b01000000	; privilege level 2
	IDT_P3 equ 0b01100000	; privilege level 3
	IDT_TaG equ 0b0000101	; gate types : task gate
	IDT_Int16 equ 0b00110	;              16-bit interrupt gate
	IDT_TrG16 equ 0b00111	;              16-bit trap gate
	IDT_Int32 equ 0b01110	;              32-bit interrupt gate
	IDT_TrG32 equ 0b01111	;              32-bit trap gate

	; IDT header. In comparison with the GDT header it must be
	; placed before actual table (there is no null entry)
section .data
	idt_size equ 8*256
IDTH:
	dw idt_size
	dd IDT
	
section .bss
IDT:
	resb idt_size
