;;; Pile of hacks
;;; all unsorted procedures are here
global strlen
global memcpy
global memset
global strcpy
global puts
global putchar
global getchar
global printf
global fork
global trace

%include "def/ph.s"
%include "def/idt.s"

extern vga_putc
extern vga_flush
extern malloc
extern kbdbf
extern getbb

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

;; OUT:
;; eax — 8 bit ASCII character
getchar:
        mov eax, [kbdbf]
        push eax
        call getbb
        add esp, 4
        ret

section .data
trace_format:
        db `%d [esp+%d] %d\n`, 0
regs_format:
        db `EAX: %d, EBX: %d, ECX: %d, EDX: %d\n`
        db `ESI: %d, EDI: %d, ESP: %d, EBP: %d\n`, 0
section .text
trace:
        enter 36, 0
        mov long [esp], regs_format
        mov [esp+4], eax
        mov [esp+8], ebx
        mov [esp+12], ecx
        mov [esp+16], edx
        mov [esp+20], esi
        mov [esp+24], edi
        mov [esp+28], esp
        mov [esp+32], ebp
        call printf

        mov long [esp], trace_format
        mov [esp+32], ebx
        mov ebx, 4*20
.loop:
        lea eax, [ebp+ebx]
        mov [esp+4], eax
        mov [esp+8], ebx
        mov eax, [ebp+ebx]
        mov [esp+12], eax
        call printf
        sub ebx, 4
        cmp ebx, 4
        jge .loop
        mov ebx, [esp+32]
        leave
        ret

;; Put an ASCII string onto the screen after the current cursor
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
        cmp al, 'c'
        je .arg_c
        jmp .loop
.arg_c:
        add ebx, 4
        mov eax, [ebp+ebx]
        mov [esp], eax
        call vga_putc
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

memcpy:
        push ebx
	mov ebx, [esp+8]
	mov edx, [esp+12]
	mov ecx, [esp+16]
        inc ecx
.alien_invasion:
	mov al, [edx+ecx-1]
	mov [ebx+ecx-1], al
        loop .alien_invasion
        pop ebx
        ret

;; This function fills the memory with blood o_0
;; IN:
;; [esp+4] — 32 bit pointer to the memory region
;; [esp+8] — 32 bit character to fill them memory with
;; [esp+12] — 32 bit number of bytes to set
memset:
        mov eax, [esp+4]
        mov edx, [esp+8]
        mov ecx, [esp+12]
.tomato_monster:
        cmp ecx, 0
        retz
        mov [eax], dl
        inc eax
        dec ecx
        jmp .tomato_monster

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
