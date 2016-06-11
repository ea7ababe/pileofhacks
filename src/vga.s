;;; VGA text mode driver
global vga_init
global vga_flush, vga_clear
global vga_putc, vga_putchar, vga_puts
global vga_set_pointer

extern memcpy

%define SCREEN 0xB8000
%define SCREEN_WIDTH  80*2
%define SCREEN_HEIGHT 25
%define SCREEN_SIZE 2*80*25

%define COLOR_BLACK 0
%define COLOR_BLUE 1
%define COLOR_GREEN 2
%define COLOR_CYAN 3
%define COLOR_RED 4
%define COLOR_MAGENTA 5
%define COLOR_BROWN 6
%define COLOR_LIGHT_GREY 7
%define COLOR_DARK_GREY 8
%define COLOR_LIGHT_BLUE 9
%define COLOR_LIGHT_GREEN 10
%define COLOR_LIGHT_CYAN 11
%define COLOR_LIGHT_RED 12
%define COLOR_LIGHT_MAGENTA 13
%define COLOR_LIGHT_BROWN 14
%define COLOR_WHITE 15

section .bss
buffer:
	resb SCREEN_SIZE

section .data
cursor_position:
	dd 0
screen_color:
	db 0x07

section .text
;; Module initialization
vga_init:
	call vga_get_pointer
	shl eax, 1
	mov [cursor_position], eax
	ret

;; This one clears the screen
vga_clear:
	mov ecx, SCREEN_SIZE
	mov ah, [screen_color]
	mov al, ' '
.loop:
	sub ecx, 2
	mov [buffer+ecx], ax
	jnz .loop
	ret

;; Copies buffer contents onto the screen
vga_flush:
	push SCREEN_SIZE
	push buffer
	push SCREEN
	call memcpy

	mov ecx, [cursor_position]
	shr ecx, 1
	mov [esp], ecx
	call vga_set_pointer

	add esp, 12
	ret

;; Sets hardware pointer position
;; IN:
;; [esp+4] — 32 bit pointer offset
vga_set_pointer:
	mov ecx, [esp+4]

	mov dx, 0x3D4
	mov al, 0xF
	out dx, al

	inc dx
	mov al, cl
	out dx, al

	dec dx
	mov al, 0xE
	out dx, al

	inc dx
	mov al, ch
	out dx, al

	ret

;; Gets hardware pointer position
;; OUT:
;; eax — 32 bit pointer offset
vga_get_pointer:
	mov dx, 0x3D4
	mov al, 0xF
	out dx, al

	inc dx
	in al, dx
	mov cl, al

	dec dx
	mov al, 0xE
	out dx, al

	inc dx
	in al, dx
	mov ch, al

	xor eax, eax
	mov ax, cx
	ret

;; Puts a character onto the screen to the current cursor position
;; IN:
;; [esp+4] — 8 bit ASCII character
vga_putc:
        push esi
        push edi
	mov ecx, [esp+12]
	mov ch, [screen_color]
	mov esi, [cursor_position]

        cmp cl, `\b`
        je .backspace
	cmp cl, `\n`
	je .new_line

	mov [buffer+esi], cx	; put character into the buffer
	add esi, 2
	jmp .test_eos

.backspace:
        sub esi, 2
        mov [cursor_position], esi
        mov word [buffer+esi], ' '
        jmp .ret

.new_line:			; calculate next line location
	mov eax, esi
	xor edx, edx
	mov edi, SCREEN_WIDTH
	idiv edi
	sub edi, edx
	add esi, edi

.test_eos:			; check for buffer overflow
	cmp esi, SCREEN_SIZE
	je .scroll
	mov [cursor_position], esi
	jmp .ret

.scroll:			; scroll one line down
	mov eax, SCREEN_WIDTH
.scroll_copy:
	mov dx, [buffer+eax]
	mov [buffer-SCREEN_WIDTH+eax], dx
	add eax, 2
	cmp eax, SCREEN_SIZE
	jne .scroll_copy

	mov dh, [screen_color]
	mov dl, ' '
.scroll_clear:			; fill the last string with spaces
	sub eax, 2
	mov [buffer+eax], dx
	cmp eax, SCREEN_SIZE-SCREEN_WIDTH
	jne .scroll_clear
	mov [cursor_position], eax
.ret:
        pop edi
        pop esi
	ret
