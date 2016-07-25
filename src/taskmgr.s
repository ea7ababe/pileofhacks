;;; Multitasking
;;; The art of doing twice as much as you should
;;; half as well as you could

global taskmgr_init

global base_process
global base_process_stack

%include "def/mmu.s"
%include "def/i8259.s"
%include "def/taskmgr.s"
%include "def/idt.s"

extern idt_set
extern malloc
extern trace
extern puts
extern die_with_honor

section .bss
current_task:
	resd 1
base_process:
	resb Task.size
base_process_stack:
        resb STACKSZ

section .text
taskmgr_init:
	; setup protection fault hander
	; should it even be here?
	push 13
	push int13_handler
	call idt_set

	mov long [esp+4], 14
	mov long [esp], int14_handler
	call idt_set

        ; PIT interrupt for task switching
	mov long [esp+4], IDT_TS
	mov long [esp], switch_task
	call idt_set

        ; fork interrupt
        ;mov long [esp+4], IDT_FORK
        ;mov long [esp], fork_handler
        ;call idt_set

	; fill bootstrap process structure
	mov eax, base_process
	mov [current_task], eax
	mov [eax+Task.next_task], eax
	mov [eax+Task.prev_task], eax
        mov long [eax+Task.stbase], base_process_stack

	add esp, 8
	ret

;; interrupt handler for task switching
switch_task:
        cli
        pusha
        mov eax, [current_task]
        mov [eax+Task.esp], esp
        mov eax, [eax+Task.next_task]
        mov esp, [eax+Task.esp]
	mov al, PIC_EOI
	out MPICC, al
        popa
        sti
        iret

;; general protection fault handler
section .data
        int13_message db `Segmentation fault, trace invoked.`, 0
section .text
int13_handler:
        call trace
        mov long [esp], int13_message
        call puts
	mov eax, 13FA12h
	jmp die_with_honor

;; page fault handler
section .data
        int14_message db `Page fault, trace invoked.`, 0
section .text
int14_handler:
        call trace
        mov long [esp], int14_message
        call puts
	mov eax, 14FA12h
	jmp die_with_honor
