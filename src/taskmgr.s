;;; Multitasking
;;; The art of doing twice as much as you should
;;; half as well as you could

global taskmgr_init
global move_your_ass

%include "def/mmu.s"
%include "def/taskmgr.s"

extern idt_set
extern die_with_honor
extern get_free_paper
extern return_page

section .bss
current_process:
	resd 1

bootstrap_process:
	resb Task.size

alignb 0x1000
bootstrap_page_dir:
	resb PDSIZE

section .text
taskmgr_init:
	; setup protection fault hander;
	; should it even be here?
	push 13
	push int13_handler
	call idt_set

	mov long [esp+4], 14
	mov long [esp], int14_handler
	call idt_set

	; fill bootstrap process structure
	mov eax, bootstrap_process
	mov [current_process], eax
	mov long [eax+Task.cr3], bootstrap_page_dir
	mov long [eax+Task.next_task], bootstrap_process
	mov long [eax+Task.prev_task], bootstrap_process
	; load page directory
	mov ecx, bootstrap_page_dir
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

	; Changes the current heap size.
	; GETS:
	; [esp+4] — required program break
	; RETURNS:
	; eax — a pointer to the last byte of available memory
move_your_ass:
	mov ecx, [esp+4]
	shr ecx, 20
	mov esi, [current_process]
	mov esi, [esi+Task.cr3]
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

;; general protection fault handler
int13_handler:
	mov eax, 13FA12h
	jmp die_with_honor

;; page fault handler
int14_handler:
	mov eax, 14FA12h
	jmp die_with_honor
