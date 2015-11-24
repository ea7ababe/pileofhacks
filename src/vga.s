;;; vga: the vga-compatible video cards driver
global vga_init
global vga_flush, vga_clear
global vga_putc, vga_putchar, vga_puts
	
extern memcpy
	
	SCREEN equ 0xB8000
	SCREEN_WIDTH equ  80*2
	SCREEN_HEIGHT equ 25
	SCREEN_SIZE equ 2*80*25

	COLOR_BLACK equ 0
	COLOR_BLUE equ 1
	COLOR_GREEN equ 2
	COLOR_CYAN equ 3
	COLOR_RED equ 4
	COLOR_MAGENTA equ 5
	COLOR_BROWN equ 6
	COLOR_LIGHT_GREY equ 7
	COLOR_DARK_GREY equ 8
	COLOR_LIGHT_BLUE equ 9
	COLOR_LIGHT_GREEN equ 10
	COLOR_LIGHT_CYAN equ 11
	COLOR_LIGHT_RED equ 12
	COLOR_LIGHT_MAGENTA equ 13
	COLOR_LIGHT_BROWN equ 14
	COLOR_WHITE equ 15

section .bss
buffer:
	resb SCREEN_SIZE
	
section .data
cursor_position:
	dd 0
screen_color:
	db 0x70

section .text
vga_init:
	call vga_clear
	call vga_flush
	ret

vga_clear:
	mov ecx, SCREEN_SIZE
	mov ah, [screen_color]
	mov al, ' '
.loop:
	sub ecx, 2
	mov [ecx+buffer], ax
	jnz .loop
	ret
	
vga_flush:
	push SCREEN_SIZE	; copy
	push buffer		; buffer
	push SCREEN		; to
	call memcpy		; screen
	add  esp, 12

	mov ecx, [cursor_position]
	shr ecx, 1

	mov dx, 0x3D4		; and
	mov al, 0xF		; move
	out dx, al		; cursor
	
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

vga_putc:
	mov ecx, [esp+4]
	mov ch, [screen_color]
	mov esi, [cursor_position]
	
	cmp cl, `\n`		; check if character is a new line
	je .new_line

	mov [buffer+esi], cx	; put character into the buffer
	add esi, 2
	jmp .test_eos

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
	ret

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
	ret

vga_putchar:
	mov eax, [esp+4]
	push eax
	call vga_putc
	add esp, 4
	call vga_flush
	ret

vga_puts:
	mov esi, [esp+4]
	enter 8, 0
	mov long [esp], 0

.loop:
	mov al, [esi]
	inc esi
	test al, al
	jz .return

	mov [esp+4], esi
	mov [esp], al
	call vga_putc
	mov esi, [esp+4]
	jmp .loop

.return:
	call vga_flush
	leave
	ret
