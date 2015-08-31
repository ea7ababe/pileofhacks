### misc: some usefull stuff
	.global return
	.global itoa
	.global strlen
	.global memcpy
	
	.section .text
	## just return for jz
return:
	ret

	## int -> str
itoa:
	mov 4(%esp), %eax
	mov 8(%esp), %esi
	add $10, %esi
	movb $0, (%esi)
	dec %esi
	xor %edx, %edx
	mov $10, %ecx

	.itoa.cond:
	cmp %eax, %ecx
	jg .itoa.end

	idiv %ecx
	add $0x30, %edx
	mov %dl, (%esi)
	xor %edx, %edx
	dec %esi
	jmp .itoa.cond

	.itoa.end:
	add $0x30, %eax
	mov %al, (%esi)
	mov %esi, %eax
	ret

	## str -> length
strlen:
	mov 4(%esp), %ecx
	xor %eax, %eax

	.strlen.next:
	mov (%ecx), %dl

	test %dl, %dl
	jz return
	inc %eax
	inc %ecx
	jmp .strlen.next

	## (dst, src, length) -> IO
memcpy:
	mov 4(%esp), %edi
	mov 8(%esp), %esi
	mov 12(%esp), %ecx

	.memcpy.loop:
	test %ecx, %ecx
	jz return

	mov (%esi), %al
	mov %al, (%edi)
	inc %esi
	inc %edi
	dec %ecx
	jmp .memcpy.loop
