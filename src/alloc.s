;;; Simple memory allocator
global allot_init
global allot

%include "def/alloc.s"
%include "def/error.s"
%include "def/mmu.s"

extern move_your_ass

extern ksize

section .text
allot_init:
	push 0
	call move_your_ass

	mov ecx, KZERO
	add ecx, ksize		;0x10b024 for now
	sub eax, ecx
	sub eax, Memhdr.size
	and eax, ~MAFLAGS
	or  eax, MAEOM
	mov long [ecx+Memhdr.prhd], 0
	mov long [ecx+Memhdr.data], eax

	add esp, 4
	ret

	; GET:
	; [esp+4] — required memory size
	; RETURN:
	; eax — pointer to allocated memory on success
	;     — zero on fail
	; DESCRIPTION:
	; Big, fat and slow memory allocator.
	; BUGS:
	; Crashes trying to allocate more pages.
allot:
	mov edx, [esp+4]
	add edx, MAMDSIZE-1
	and edx, ~MAFLAGS
	mov eax, KZERO
	add eax, ksize
	xor edi, edi

	; eax - base address
	; edi - offset to next sector
	; edx - required size
.check_next_sector:
	; fitch next sector
	add eax, edi
	mov ecx, [eax+Memhdr.data]
	mov edi, ecx
	and edi, ~MAFLAGS
	; if sector is used
	test ecx, MAUSED
	; try fitch next sector
	jnz .try_fitch_next_sector
	; else if sector size ≥ required
	cmp edi, edx
	; success
	jge .split_n_get
	; else try fitch next sector
	add edi, Memhdr.size

	; eax - base address
	; ecx - current sector flags
	; edi - offset to next sector
	; edx - required size
.try_fitch_next_sector:
	; if not end of memory
	test ecx, MAEOM
	; NEXT
	jz .check_next_sector
	; else allocate some memory
	push edx
	push eax
	add eax, edi
	push eax
	add eax, edx
	add eax, Memhdr.size
	push eax
	call move_your_ass
	; if new break < required break
	mov ecx, [esp]
	cmp eax, ecx
	; then fail
	jl .fail
	; else create new sector
	mov edi, eax
	mov eax, [esp+4]
	mov esi, [esp+8]
	mov edx, [esp+12]
	add esp, 16

	; eax - base address
	; esi - previous header address
	; edi - end address
	; edx - required size
.create_new_sector:
	mov [eax+Memhdr.prhd], esi
	sub edi, eax
	sub edi, Memhdr.size
	or  edi, MAEOM
	mov [eax+Memhdr.data], edi
	xor edi, edi
	jmp .check_next_sector

	; eax - base address
	; edi - sector data size
	; edx - required size
.split_n_get:
	mov ecx, edi
	sub ecx, edx
	sub ecx, Memhdr.size
	cmp ecx, MAMDSIZE
	jl .success

	mov esi, [eax+Memhdr.data]
	and esi, MAFLAGS
	mov edi, esi
	or  esi, edx
	or  esi, MAUSED
	and esi, ~MAEOM
	mov [eax+Memhdr.data], esi

	add edx, Memhdr.size
	add edx, eax
	or  ecx, edi
	mov [edx+Memhdr.prhd], eax
	mov [edx+Memhdr.data], ecx

	; eax - sector base address
.success:
	add eax, Memhdr.size
	ret

.fail:
	xor eax, eax
	ret
