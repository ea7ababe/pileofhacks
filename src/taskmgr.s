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
	;mov long [esp+4], IDT_TS
	;mov long [esp], switch_task
	;call idt_set

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


;; IDEA!
;; Implement a buffer.
;; One writer, many readers.
;; Buffer also has a process queue.
;; Every process, that is waiting for the data in the buffer is placed
;; in its queue and removed from the active one!
;; Sounds awful.

;; task id generator
gen_id:
        ; TODO:
        ; if last task id < ~0
        ;  ret (last task id + 1)
        ; else
        ;  scan for (id delta > 1)
        ;  if found return id
        ;  else ret 0

coroutine:

;; interrupt handler for creating new task
; fork_handler:
;         ; UNTESTED
;         mov ecx, [current_task]
;         ; ecx = current task
;         mov edi, esp
;         sub edi, [ecx+Task.stbase]
;         ; edi = new task stack offset
;         enter 8, 0
;         mov long [esp], Task.size
;         call malloc
;         mov esi, eax
;         ; esi = new task entry
;         mov edx, [ecx+Task.next_task]
;         ; edx = next task
;         ; insert new task in the queue:
;         mov long [ecx+Task.next_task], esi
;         mov long [edx+Task.prev_task], esi
;         mov long [esi+Task.prev_task], ecx
;         mov long [esi+Task.next_task], edx
;         ; create task call stack:
;         mov long [esp], STACKSZ
;         call malloc
;         ; eax = new task stack base
;         ; set new task stack pointer and base:
;         mov [esi+Task.stbase], eax
;         add eax, edi
;         mov [ecx+Task.esp], eax

;         leave
;         iret

;; interrupt handler for task switching
; switch_task:
;         pusha
;         mov eax, [current_task]
;         mov [eax+Task.esp], esp
;         mov eax, [eax+Task.next_task]
;         mov esp, [eax+Task.esp]
; 	mov al, PIC_EOI
; 	out MPICC, al
;         popa
;         iret

;; general protection fault handler
int13_handler:
	mov eax, 13FA12h
	jmp die_with_honor

;; page fault handler
int14_handler:
	mov eax, 14FA12h
	jmp die_with_honor
