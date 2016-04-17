;;; Bootstrap code lives here
global _start
global halt
global die_with_honor

%include "def/ph.s"
%include "def/gdt.s"
%include "def/mmu.s"
%include "def/multiboot.s"
%include "def/taskmgr.s"

extern mmu_init
extern memmgr_init
extern vga_init
extern vga_puts
extern idt_init
extern i8259_init
extern atkbd_init
extern taskmgr_init
extern pit_init
extern main
extern tests

extern multiboot_info
extern base_process_stack

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
section .text
_start:
	; save multiboot info pointer
	mov [multiboot_info], ebx
	; setup GDT and segments
	lgdt [GDT]
        ldcs 8
	mov eax, 16
	mov ds, eax
	mov ss, eax
	mov es, eax
	mov fs, eax
	mov gs, eax
	; setup stack
	mov esp, base_process_stack
        add esp, STACKSZ
	mov eax, [ebx+MBINFO.cmdline]
	push eax

init:
	call mmu_init
	call memmgr_init
	call idt_init
	call i8259_init
        call pit_init
	call taskmgr_init
	call vga_init
	call atkbd_init
	call tests
        jmp halt
	call main

die_with_honor:
	cli
halt:
	hlt
	jmp halt
