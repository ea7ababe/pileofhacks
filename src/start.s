;;; Bootstrap code lives here
global _start
global halt

%include "def/gdt.s"
%include "def/mmu.s"

extern mmu_init
extern vga_init
extern vga_puts
extern idt_init
extern i8259_init
extern atkbd_init
extern tests
	
extern multiboot_info
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
	mov edx, KZERO
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
	; go!
	jmp init

section .text
init:
	add ebx, KZERO
	mov [multiboot_info], ebx
	call mmu_init
	call vga_init
	call idt_init
	call i8259_init
	call atkbd_init
	call tests

halt:
	hlt
	jmp halt
