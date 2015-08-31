### vga: the vga-compatible video cards driver
	.global vga_init
	.global vga_flush, vga_clear
	.global vga_putc, vga_putchar, vga_puts
	
	.set SCREEN, 0xB8000
	.set SCREEN_WIDTH,  80*2
	.set SCREEN_HEIGHT, 25
	.set SCREEN_SIZE, 2*80*25

	.set COLOR_BLACK, 0
	.set COLOR_BLUE, 1
	.set COLOR_GREEN, 2
	.set COLOR_CYAN, 3
	.set COLOR_RED, 4
	.set COLOR_MAGENTA, 5
	.set COLOR_BROWN, 6
	.set COLOR_LIGHT_GREY, 7
	.set COLOR_DARK_GREY, 8
	.set COLOR_LIGHT_BLUE, 9
	.set COLOR_LIGHT_GREEN, 10
	.set COLOR_LIGHT_CYAN, 11
	.set COLOR_LIGHT_RED, 12
	.set COLOR_LIGHT_MAGENTA, 13
	.set COLOR_LIGHT_BROWN, 14
	.set COLOR_WHITE, 15

	.section .bss
buffer:
	.skip SCREEN_SIZE
	
	.section .data
cursor_position:
	.long 0
screen_color:
	.byte 0x70

	.section .text
vga_init:
	call vga_clear
	call vga_flush
	ret

vga_clear:
	mov $SCREEN_SIZE, %ecx
	mov screen_color, %ah
	mov $' , %al
	.vga_clear.loop:
	sub $2, %ecx
	mov %ax, buffer(%ecx)
	jnz .vga_clear.loop
	ret
	
vga_flush:
	push $SCREEN_SIZE	# copy
	push $buffer		# buffer
	push $SCREEN		# to
	call memcpy		# screen
	add $12, %esp

	mov cursor_position, %ecx
	shr $1, %ecx

	mov $0x3D4, %dx		# and
	mov $0xF, %al		# move
	out %al, %dx		# cursor
	
	inc %dx
	mov %cl, %al
	out %al, %dx
	
	dec %dx
	mov $0xE, %al
	out %al, %dx
	
	inc %dx
	mov %ch, %al
	out %al, %dx
	
	ret

vga_putc:
	mov 4(%esp), %ecx
	mov screen_color, %ch
	mov cursor_position, %esi
	
	cmp $'\n, %cl		# check if character is a new line
	je .vga_putc.new_line

	mov %cx, buffer(%esi) # put character into the buffer
	add $2, %esi
	jmp .vga_putc.test_eos

	.vga_putc.new_line:	# calculate next line location
	mov %esi, %eax
	xor %edx, %edx
	mov $SCREEN_WIDTH, %edi
	idiv %edi
	sub %edx, %edi
	add %edi, %esi

	.vga_putc.test_eos:	# check for buffer overflow
	cmp $SCREEN_SIZE, %esi
	je .vga_putc.scroll
	mov %esi, cursor_position
	ret

	.vga_putc.scroll:	# scroll one scring down
	mov $SCREEN_WIDTH, %eax
	.vga_putc.scroll.copy:
	mov buffer(%eax), %dx
	mov %dx, buffer-SCREEN_WIDTH(%eax)
	add $2, %eax
	cmp $SCREEN_SIZE, %eax
	jne .vga_putc.scroll.copy
	
	mov screen_color, %dh
	mov $' , %dl
	.vga_putc.scroll.clear:	# fill the last string with spaces
	sub $2, %eax
	mov %dx, buffer(%eax)
	cmp $SCREEN_SIZE-SCREEN_WIDTH, %eax
	jne .vga_putc.scroll.clear
	
	mov %eax, cursor_position
	ret

vga_putchar:
	mov 4(%esp), %eax
	push %eax
	call vga_putc
	add $4, %esp
	call vga_flush
	ret

vga_puts:
	mov 4(%esp), %esi
	enter $8, $0
	movl $0, (%esp)

	.vga_puts.loop:
	mov (%esi), %al
	inc %esi
	test %al, %al
	jz .vga_puts.return

	mov %esi, 4(%esp)
	mov %al, (%esp)
	call vga_putc
	mov 4(%esp), %esi
	jmp .vga_puts.loop

	.vga_puts.return:
	call vga_flush
	leave
	ret
