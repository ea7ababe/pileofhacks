;;; Pile of hacks
;;; all unsorted procedures are here
global itoa
global strlen
global memcpy
global strcpy
global puts
global putchar
global printf
global fork

%include "def/ph.s"
%include "def/idt.s"

extern vga_putc
extern vga_flush
extern malloc

section .text
fork:
        int IDT_FORK
        ret

putchar:
	mov eax, [esp+4]
	push eax
	call vga_putc
	call vga_flush
	add esp, 4
	ret

;; Puts an ASCII string onto the screen after the current cursor
;; position
;; IN:
;; [esp+4] — 32 bit pointer to the ASCII string to print
puts:
        push esi
	enter 4, 0
	mov esi, [ebp+12]
	mov long [esp], 0
.loop:
	mov al, [esi]
	inc esi
	test al, al
	jz .return
	mov [esp], al
	call vga_putc
	jmp .loop
.return:
	call vga_flush
	leave
        pop esi
	ret

;; Formatted output to vga interface
;; IN:
;; [esp+4] — pointer to format string
;; [esp+8,...] — format arguments
printf:
        push ebx
        push esi
        push edi
        enter 20, 0
        mov esi, [ebp+20]
        mov ebx, 20
.loop:
        mov al, [esi]
        inc esi
        cmp al, 0
        je .fin
        cmp al, '%'
        je .arg
.putc:
        mov [esp], al
        call vga_putc
        jmp .loop
.arg:
        mov al, [esi]
        inc esi
        cmp al, 0
        je .fin
        cmp al, '%'
        je .putc
        cmp al, 'd'
        je .arg_d
        cmp al, 's'
        je .arg_s
        jmp .loop
.arg_s:
        add ebx, 4
        mov eax, [ebp+ebx]
        mov [esp], eax
        call puts
        jmp .loop
.arg_d:
        add ebx, 4
        mov eax, [ebp+ebx]
        lea edi, [ebp-1]
        mov byte [edi], 0
        mov ecx, 10
.arg_d_1:
        dec edi
        cmp eax, ecx
        jl .arg_d_f
        xor edx, edx
        idiv ecx
        add dl, 30h
        mov [edi], dl
        jmp .arg_d_1
.arg_d_f:
        add al, 30h
        mov [edi], al
        mov [esp], edi
        call puts
        jmp .loop
.fin:
        call vga_flush
        leave
        pop edi
        pop esi
        pop ebx
        ret

	; (number int32) -> (string *char)
itoa:
        push 11
        call malloc
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
        retz
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
	retz

	mov al, [esi]
	mov [edi], al
	inc esi
	inc edi
	dec ecx
	jmp .loop

;; Copy strings
;; IN:
;; [esp+4] — 32 bit address of the destination string
;; [esp+8] — 32 bit address of the source string
strcpy:
        mov edi, [esp+4]
        mov esi, [esp+8]
.loop:
        mov al, [esi]
        mov [edi], al
        inc esi
        inc edi
        test al, al
        jnz .loop
        ret
