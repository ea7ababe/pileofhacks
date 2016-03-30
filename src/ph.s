;;; Pile of hacks
;;; all unsorted procedures are here
global itoa
global strlen
global memcpy
global puts

extern vga_puts
extern allot

section .text
	; just return for jz
return:
	ret

	; temporary blob
puts:
	mov eax, [esp+4]
	push eax
	call vga_puts
	add esp, 4
	ret

	; (number int32) -> (string *char)
itoa:
        push 11
        call allot
        add esp, 4
        mov esi, eax
	mov eax, [esp+4]
	add esi, 10
	mov byte [esi], 0
	dec esi
	xor edx, edx
	mov ecx, 10

	.cond:
	cmp ecx, eax
	jg .end

	idiv ecx
	add edx, 30h
	mov [esi], dl
	xor edx, edx
	dec esi
	jmp .cond

	.end:
	add eax, 30h
	mov [esi], al
	mov eax, esi
	ret

	; (string *char) -> (length uint32)
strlen:
	mov ecx, [esp+4]
	xor eax, eax

	.next:
	mov dl, [ecx]

	test dl, dl
	jz return
	inc eax
	inc ecx
	jmp .next

	; (dst, src *void, length uint32) -> ()
memcpy:
	mov edi, [esp+4]
	mov esi, [esp+8]
	mov ecx, [esp+12]

	.loop:
	test ecx, ecx
	jz return

	mov al, [esi]
	mov [edi], al
	inc esi
	inc edi
	dec ecx
	jmp .loop
