;;; Simple memory allocator.

global memmgr_init
global allot

%include "def/memmgr.s"
%include "def/error.s"
%include "def/mmu.s"

extern get_free_paper
extern lock_page, unlock_page

section .bss
        start resd 1
        break resd 1
alignb 1000h
        page_dir resb PDSIZE

section .text
memmgr_init:
        call go_virtual
        call make_mem_pool
        ret

;; fills page directory and enables paging
go_virtual:
        mov eax, PROGSIZE
        mov [start], eax
        or  eax, 3FFFFFh
        mov [break], eax
        xor ecx, ecx
.fill_pd:
        cmp ecx, eax
        jg .load_pd
        mov edx, ecx
        shr edx, 20
        or ecx, PDPR|PDRW|PDSZ
        mov [page_dir+edx], ecx
        push eax
        push ecx
        call lock_page
        pop ecx
        pop eax
        add ecx, PGSIZE
        jmp .fill_pd

.load_pd:
        mov eax, page_dir
	mov cr3, eax
	; enable 4MiB pages and global flags
	mov ecx, cr4
	or  ecx, CR4PSE|CR4GL
	mov cr4, ecx
	; enable paging
	mov ecx, cr0
	or  ecx, CR3PE
	mov cr0, ecx

.make_first_sector:
        mov eax, [start]
        mov ecx, [break]
        sub ecx, eax
        and ecx, MANF
        mov long [eax+Memhdr.prhd], 0
        mov long [eax+Memhdr.data], ecx
        ret

;; initializes a memory pool
make_mem_pool:
        mov eax, [start]
        mov long [eax+Memhdr.prhd], 0

        mov edx, [break]
        sub edx, eax
        sub edx, Memhdr.size
        and edx, MANF
        mov [eax+Memhdr.data], edx

        ret

;; allocates physical memory and inserts it into the page table
;; IN:
;; [esp+4] — 32 bit address of the new break
extend:


;; allocates memory of required size
;; IN:
;; [esp+4] — 32 bit memory size
;; OUT:
;; eax — pointer to allocated memory or 0 on error
allot:
        mov eax, [esp+4]
        mov esi, [start]
        mov edi, [break]
        call find_free_sector
        cmp eax, 0
        ret

;; finds a free sector with size more or equal to the required
;; IN:
;; eax — required sector size
;; esi — where to start searching
;; edi — where to stop searching
;; OUT:
;; eax — address of the sector or 0 on error
;; ecx — address of the last checked sector (for use with 0 eax)
;; AFFECTS: eax, ecx, edx
find_free_sector:
        mov ecx, esi
.loop:
        mov edx, [ecx+Memhdr.data]
        and edx, MANF
        cmp eax, edx
        jge .return
        add ecx, edx
        add ecx, Memhdr.size
        mov edx, [ecx+Memhdr.data]
        bt edx, MAEND
        jc .fail
        jmp .loop
.fail:
        xor eax, eax
        ret
.return:
        mov eax, ecx
        ret

;; TO DELETE
; allot_init:
; 	push 0
; 	call move_your_ass

; 	mov ecx, KZERO
; 	add ecx, KSIZE
; 	sub eax, ecx
; 	sub eax, Memhdr.size
; 	and eax, ~MAFLAGS
; 	or  eax, MAEOM
; 	mov long [ecx+Memhdr.prhd], 0
; 	mov long [ecx+Memhdr.data], eax

; 	add esp, 4
; 	ret

;; TO DELETE
;; GET:
;; [esp+4] — required memory size
;; RETURN:
;; eax — pointer to allocated memory on success
;;       zero on fail
;; DESCRIPTION:
;; Big, fat and slow memory allocator.
;; BUGS:
;; Crashes trying to allocate more pages.
; allot:
; 	mov edx, [esp+4]
; 	add edx, MAMDSIZE-1
; 	and edx, ~MAFLAGS
; 	mov eax, KZERO
; 	add eax, KSIZE
; 	xor edi, edi

; 	; eax - base address
; 	; edi - offset to next sector
; 	; edx - required size
; .check_next_sector:
; 	; fitch next sector
; 	add eax, edi
; 	mov ecx, [eax+Memhdr.data]
; 	mov edi, ecx
; 	and edi, ~MAFLAGS
; 	; if sector is used
; 	test ecx, MAUSED
; 	; try fitch next sector
; 	jnz .try_fitch_next_sector
; 	; else if sector size ≥ required
; 	cmp edi, edx
; 	; success
; 	jge .split_n_get
; 	; else try fitch next sector
; 	add edi, Memhdr.size

; 	; eax - base address
; 	; ecx - current sector flags
; 	; edi - offset to next sector
; 	; edx - required size
; .try_fitch_next_sector:
; 	; if not end of memory
; 	test ecx, MAEOM
; 	; NEXT
; 	jz .check_next_sector
; 	; else allocate some memory
; 	push edx
; 	push eax
; 	add  eax, edi
; 	push eax
; 	add  eax, edx
; 	add  eax, Memhdr.size
; 	push eax
; 	call move_your_ass
; 	; if new break < required break
; 	mov ecx, [esp]
; 	cmp eax, ecx
; 	; then fail
; 	jl .fail
; 	; else create new sector
; 	mov edi, eax
; 	mov eax, [esp+4]
; 	mov esi, [esp+8]
; 	mov edx, [esp+12]
; 	add esp, 16

; 	; eax - base address
; 	; esi - previous header address
; 	; edi - end address
; 	; edx - required size
; .create_new_sector:
; 	mov [eax+Memhdr.prhd], esi ; page fault somewhere around
; 	sub edi, eax
; 	sub edi, Memhdr.size
; 	or  edi, MAEOM
; 	mov [eax+Memhdr.data], edi
; 	xor edi, edi
; 	jmp .check_next_sector

; 	; eax - base address
; 	; edi - sector data size
; 	; edx - required size
; .split_n_get:
; 	mov ecx, edi
; 	sub ecx, edx
; 	sub ecx, Memhdr.size
; 	cmp ecx, MAMDSIZE
; 	jl .success

; 	mov esi, [eax+Memhdr.data]
; 	and esi, MAFLAGS
; 	mov edi, esi
; 	or  esi, edx
; 	or  esi, MAUSED
; 	and esi, ~MAEOM
; 	mov [eax+Memhdr.data], esi

; 	add edx, Memhdr.size
; 	add edx, eax
; 	or  ecx, edi
; 	mov [edx+Memhdr.prhd], eax
; 	mov [edx+Memhdr.data], ecx

; 	; eax - sector base address
; .success:
; 	add eax, Memhdr.size
; 	ret

; .fail:
; 	xor eax, eax
; 	ret
