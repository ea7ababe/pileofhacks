;;; Not so simple memory allocator.
;;; TODO:
;;; This needs a full rewrite, it's not thread safe.
;;; I think some parts should be integrated with the task manager.
;;; Update: maybe I should just give up with preemptive multitasking
;;; and everything will be ok then.

global memmgr_init
global malloc, extend
global start, break

%include "def/memmgr.s"
%include "def/error.s"
%include "def/mmu.s"
%include "def/ph.s"

extern get_free_paper
extern lock_page, unlock_page
extern current_process

section .bss
        start resd 1
        break resd 1
alignb 1000h
        page_dir resb PDSIZE

section .text
memmgr_init:
        mov eax, PROGSIZE
        mov [start], eax
        or  eax, 3FFFFFh
        mov [break], eax
        mov ecx, PDPR|PDRW|PDSZ
.fill_pd:
        cmp ecx, eax
        jg .load_pd
        mov edx, ecx
        shr edx, 20
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
        sub ecx, Memhdr.size
        and ecx, MANF
        bts ecx, MAEND
        mov long [eax+Memhdr.prhd], 0
        mov long [eax+Memhdr.data], ecx
        ret

;; allocates physical memory and inserts it into the page table
;; IN:
;; [esp+4] — 32 bit size of required memory
;; OUT:
;; eax — 32 bit new break address or 0 on error
;; TODO:
;; Must return 0 on error; add get_free_paper error check.
extend:
        xor eax, eax
        mov edx, [break]
        add edx, 1
        shr edx, 20
        mov ecx, [esp+4]
        cmp ecx, 0
        retz
.loop:
        push edx
        push ecx
        call get_free_paper
        pop ecx
        pop edx
        or eax, PDPR|PDRW|PDSZ
        mov [page_dir+edx], eax
        invlpg [eax]
        add edx, PDESZ
        sub ecx, PGSIZE
        cmp ecx, 0
        jg .loop
.ret:
        shl edx, 20
        sub edx, 1
        mov [break], edx
        ret

;; allocates memory of required size
;; IN:
;; [esp+4] — 32 bit size of memory to allocate
;; OUT:
;; eax — 32 bit pointer to allocated memory or 0 on error
;; ALGORITHM:
;; if find_free_sector = success
;;    split sector if possible
;;    mark sector as used
;;    return address of the data block
;; else
;;    if extend = 0
;;       return 0
;;    make new sector filling all size returned by extend
;;    do all that stuff from find_free_sector = success
malloc:
        push esi
        push edi
        mov eax, [esp+12]
        add eax, MAAF
        and eax, MANF
        push eax
        call find_free_sector
        cmp eax, 0
        jnz .not_found
.found:
        pop eax
        call split
        mov eax, [esi+Memhdr.data]
        bts eax, MAUSED
        mov [esi+Memhdr.data], eax
        lea eax, [esi+Memhdr.size]
        jmp .ret
.not_found:
        ; UNTESTED, UGLY, NEEDS REWRITE
        ; call extend with required memory size + header size
        pop eax
        add eax, Memhdr.size
        push eax
        call extend
        ; return 0 if no physical memory available
        cmp eax, 0
        jz .ret
        ; save new break in edi
        mov edi, eax
        ; clear END flag of the last sector
        pop eax
        sub eax, Memhdr.size
        mov ecx, [esi+Memhdr.data]
        mov edx, ecx
        and edx, MANF
        btr ecx, MAEND
        mov [esi+Memhdr.data], ecx
        ; make new sector after the last one
        mov ecx, esi
        lea esi, [esi+edx+Memhdr.size]
        sub edi, esi
        sub edi, Memhdr.size
        and edi, MANF
        bts edi, MAEND
        mov [esi+Memhdr.prhd], ecx
        mov [esi+Memhdr.data], edi
        push eax
        jmp .found
.ret:
        pop edi
        pop esi
        ret

;; finds a free sector with size more or equal to the required
;; IN:
;; eax — required sector size
;; OUT:
;; eax — error code (0 — success, 1 — no sector of required size found)
;; esi — address of the last checked sector
find_free_sector:
        mov esi, [start]
        mov edi, [break]
.loop:
        mov ecx, [esi+Memhdr.data]
        mov edx, ecx
        and edx, MANF
        bt ecx, MAUSED
        jc .next
        cmp eax, edx
        jle .success
.next:
        bt ecx, MAEND
        jc .not_found
        lea esi, [esi+edx+Memhdr.size]
        jmp .loop
.not_found:
        mov eax, 1
        ret
.success:
        mov eax, 0
        ret

;; split one big sector on two lesser sectors
;; IN:
;; esi — 32 bit address of the sector to split
;; eax — 32 bit size of the first sector
;; OUT:
;; esi — 32 bit address of the first subsector (its header)
split:
        mov ecx, [esi+Memhdr.data]
        mov edx, ecx
        and edx, MAAF
        ; calculate second sector size
        and ecx, MANF
        sub ecx, eax
        sub ecx, Memhdr.size
        cmp ecx, MAMDSZ
        jl .return
        ; patch first header
        mov edi, eax
        or edi, edx
        btr edi, MAEND
        mov [esi+Memhdr.data], edi
        ; create second header
        lea edi, [esi+eax+Memhdr.size]
        and edx, (1<<MAEND)
        or ecx, edx
        mov [edi+Memhdr.prhd], esi
        mov [edi+Memhdr.data], ecx
.return:
        ret
