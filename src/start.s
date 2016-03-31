;;; Bootstrap code lives here
global _start
global halt
global die_with_honor

%include "def/gdt.s"
%include "def/mmu.s"
%include "def/multiboot.s"

extern mmu_init
extern vga_init
extern vga_puts
extern idt_init
extern i8259_init
extern atkbd_init
extern taskmgr_init
extern pit_init
extern allot_init
extern main
extern tests

extern multiboot_info

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
	; save multiboot info pointer
	mov [multiboot_info], ebx
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
	mov eax, [ebx+MBINFO.cmdline]
	push eax
	; go!
	jmp init

section .text
init:
	call mmu_init
	call idt_init
	call i8259_init
        call pit_init
	call taskmgr_init
	call allot_init
	call vga_init
	call atkbd_init
	call tests
	call main
	jmp halt

die_with_honor:
	cli
halt:
	hlt
	jmp halt
