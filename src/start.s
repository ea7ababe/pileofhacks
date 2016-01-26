;;; Bootstrap code lives here
global _start

%include "def/gdt.s"
	
extern vga_init
extern idt_init
extern i8259_init
extern atkbd_init
extern tests

extern VOFFSET
extern pagedir

;; Bootstrap call stack
section .call_stack alloc write nobits
stack_bottom:
	resb 4000h		; 16KiB
stack_top:

;; Bootstrap GDT (flat)
section .data
GDT:
	; header (null entry)
	dw gdt_size
	dd GDT
	dw 0
	; supervisor code segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_Ex | GDT_R
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	; supervisor data segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_W
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	; user code segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_Ex | GDT_R | GDT_P3
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	; user data segment entry
	dw 0xFFFF
	dw 0x0
	db 0x0
	db GDT_Pr | GDT_Dt | GDT_W | GDT_P3
	db 0xF | GDT_Sz | GDT_Gr
	db 0x0
	; GDT end
	gdt_size equ $-GDT-1

;; Entry point
section .boot alloc exec progbits
_start:
	; load page directory
	mov ecx, pagedir
	mov edx, VOFFSET
	sub ecx, edx
	mov cr3, ecx
	; enable 4MiB pages
	mov ecx, cr4
	or  ecx, 10h
	mov cr4, ecx
	; enable paging
	mov ecx, cr0
	or  ecx, 80000000h
	mov cr0, ecx
	; setup GDT and segments
	lgdt [GDT]
	jmp 8:.reload_cs
.reload_cs:
	mov eax, 16
	mov ds, eax
	mov ss, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	; setup stack
	mov esp, stack_top
	push ebx
	; go!
	jmp init

section .text
init:
	call vga_init
	call idt_init
	call i8259_init
	call atkbd_init
	call tests

halt:
	hlt
	jmp halt
