;;; Physical page alligator

global mmu_init
global get_free_paper
global lock_page, unlock_page

%include "def/mmu.s"
%include "def/multiboot.s"
%include "def/error.s"

extern die_with_honor

extern multiboot_info

section .bss
	; page bitmap
	; 0 means memory is not available
	; 1 means memory is available
free_pages:
	resb 128

section .text
mmu_init:
	mov esi, [multiboot_info]
	mov eax, [esi + MBINFO.flags]
	test eax, MMEMAVAIL
	jz die_with_honor

	mov ecx, [esi + MBINFO.mem_upper]
	add ecx, 1024		; include the first mebibyte
	shr ecx, 12		; convert kibibytes to pages
	xor eax, eax

.fill_page_bitmap:
	cmp ecx, BI2WD
	jl .finish_page_bitmap
	mov long [free_pages+eax], 0FFFFFFFFh
	add eax, BY2WD
	sub ecx, BI2WD
	jmp .fill_page_bitmap

.finish_page_bitmap:
	mov edx, 0FFFFFFFFh
	shl edx, cl
	not edx
	mov [free_pages+eax], edx
	ret

;; find a free page
;; OUT:
;; eax — address of page first byte or ~0 if no free pages left
get_free_paper:
	xor eax, eax

.test_cell:
        mov edi, [free_pages+eax]
        cmp edi, 0
        jz .next_cell

        bsf ecx, edi
        bts edi, ecx
        mov [free_pages+eax], edi
	shl eax, 5
	add eax, ecx
	shl eax, 22
	ret

.next_cell:
        add eax, BY2WD
	cmp eax, 128
        jl .test_cell

	mov eax, ~0
        ret

;; set the page as unavailable
;; IN:
;; [esp+4] — 32 bit memory address of any byte in page
lock_page:
        mov eax, [esp+4]
	shr eax, 22
	xor edx, edx
	mov ecx, BI2WD
	div ecx
        btr [free_pages+eax], edx
        ret

;; set the page as free
;; IN:
;; [esp+4] — 32 bit memory address of any byte in page
unlock_page:
	mov eax, [esp+4]
	shr eax, 22
	xor edx, edx
	mov ecx, BI2WD
	div ecx
	bts [free_pages+eax], edx
	ret
