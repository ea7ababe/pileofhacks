;;; Multitasking
;;; The art of doing twice as much as you should
;;; half as well as you could

global taskmgr_init
global move_your_ass

global base_process
global base_process_stack

%include "def/mmu.s"
%include "def/i8259.s"
%include "def/taskmgr.s"
%include "def/idt.s"

extern idt_set
extern die_with_honor
extern get_free_paper
extern return_page
extern allot

section .bss
current_task:
	resd 1
base_process:
	resb Task.size
base_process_stack:
        resb STACKSZ
alignb 0x1000
page_dir:
	resb PDSIZE

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
        mov long [esp+4], IDT_FORK
        mov long [esp], fork
        call idt_set

	; fill bootstrap process structure
	mov eax, base_process
	mov [current_task], eax
	mov [eax+Task.next_task], eax
	mov [eax+Task.prev_task], eax
        mov long [eax+Task.stbase], base_process_stack

	; load page directory
	mov ecx, page_dir
	mov long [ecx], PDPR|PDRW|PDSZ
	mov cr3, ecx
	; enable 4MiB pages and global flags
	mov ecx, cr4
	or  ecx, CR4PSE|CR4GL
	mov cr4, ecx
	; enable paging
	mov ecx, cr0
	or  ecx, CR3PE
	mov cr0, ecx

	add esp, 8
	ret

;; changes the current heap size.
;; IN:
;; [esp+4] — 32 bit required program break
;; OUT:
;; eax — a pointer to the last byte of available memory
move_your_ass:
	mov ecx, [esp+4]
	shr ecx, 20
	mov esi, page_dir
	; if an argument equals 0 return current break
	cmp ecx, 0
	je .find_current_break

	enter 12, 0
	mov eax, [esi+ecx]
	cmp eax, 0
	jz .add_pages

.delete_pages:
	mov [esp], eax
	mov [esp+4], ecx
	mov [esp+8], esi
	call return_page
	mov ecx, [esp+4]
	mov esi, [esp+8]
	add ecx, 4
	cmp ecx, 1000h
	je .return
	mov eax, [esi+ecx]
	cmp eax, 0
	je .delete_pages
	jmp .return

.add_pages:
	mov [esp], ecx
	mov [esp+4], esi
	call get_free_paper
	mov ecx, [esp]
	mov esi, [esp+4]
	or  eax, PDPR|PDSZ|PDRW
	mov [esi+ecx], eax
	mov cr3, esi
	sub ecx, 4
	mov eax, [esi+ecx]
	cmp eax, 0
	je .add_pages

.return:
	leave
	mov eax, [esp+4]
	or  eax, 400000h-1
	ret

.find_current_break:
	mov eax, [esi+ecx]
	cmp eax, 0
	je .return_current_block
	add ecx, 4
	jmp .find_current_break
.return_current_block:
	shl ecx, 20
	sub ecx, 1
	mov eax, ecx
	ret

;; task id generator
gen_id:
        ; TODO:
        ; if last task id < ~0
        ;  ret (last task id + 1)
        ; else
        ;  scan for (id delta > 1)
        ;  if found return id
        ;  else ret 0

;; interrupt handler for creating new task
fork:
        mov ecx, [current_task]
        ; ecx = current task
        mov edi, esp
        sub edi, [ecx+Task.stbase]
        ; edi = new task stack offset
        enter 8, 0
        mov long [esp], Task.size
        call allot
        mov esi, eax
        ; esi = new task entry
        mov edx, [ecx+Task.next_task]
        ; edx = next task
        ; insert new task in the queue:
        mov long [ecx+Task.next_task], esi
        mov long [edx+Task.prev_task], esi
        mov long [esi+Task.prev_task], ecx
        mov long [esi+Task.next_task], edx
        ; create task call stack:
        mov long [esp], STACKSZ
        call allot
        ; eax = new task stack base
        ; set new task stack pointer and base:
        mov [esi+Task.stbase], eax
        add eax, edi
        mov [ecx+Task.esp], eax

        leave
        iret

;; interrupt handler for task switching
switch_task:
        pusha
        mov eax, [current_task]
        mov [eax+Task.esp], esp
        mov eax, [eax+Task.next_task]
        mov esp, [eax+Task.esp]
        popa
        i8259_eoi
        iret

;; general protection fault handler
int13_handler:
	mov eax, 13FA12h
	jmp die_with_honor

;; page fault handler
int14_handler:
	mov eax, 14FA12h
	jmp die_with_honor
