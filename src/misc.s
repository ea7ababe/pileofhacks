;;; misc: some usefull stuff
	global return
	global itoa
	global strlen
	global memcpy
	
	section .text
	;; just return for jz
return:
	ret

	;; int -> str
itoa:
	mov eax, [esp+4]
	mov esi, [esp+8]
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

	;; str -> length
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

	;; (dst, src, length) -> IO
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
