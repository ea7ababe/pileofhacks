;;; atkbd: PS/2 keyboard module
global atkbd_init
global kb_wait, kbc_wait
global reboot

global kbdbf

%include "def/i8259.s"

%define PS2D 60h
%define PS2C 64h
%define PS2V  1h

;; PS/2 controller status byte
%define SBOF 0                  ; output buffer full flag
%define SBIF 1                  ; input buffer full flag

;; PS/2 controller configuration byte
%define CBI1 0                  ; first port interrupt
%define CBI2 1                  ; second port interrput
%define CBSF 2                  ; system flag (POST passed)
%define CBPC1 4                 ; first port clock
%define CBPC2 5                 ; second port clock
%define CBTR 6                  ; first port translation

extern idt_set
extern i8259_unmask
extern putchar
extern buffer
extern pbbnb
extern printf
extern trace

section .bss
        kbdbf resd 1
        continuation resd 1
section .data
qwerty:
        db 0
        db 0                    ; 0x01 F9  pressed
        db 0
        db 0                    ; 0x03 F5  pressed
        db 0                    ; 0x04 F3  pressed
        db 0                    ; 0x05 F1  pressed
        db 0                    ; 0x06 F2  pressed
        db 0                    ; 0x07 F12 pressed
        db 0
        db 0                    ; 0x09 F10 pressed
        db 0                    ; 0x0A F8  pressed
        db 0                    ; 0x0B F6  pressed
        db 0                    ; 0x0C F4  pressed
        db 0                    ; 0x0D TAB pressed
        db 0                    ; 0x0E `   pressed
        times 2 db 0
        db 0                    ; 0x11 LALT pressed
        db 0                    ; 0x12 LSHIFT pressed
        db 0
        db 0                    ; 0x14 LCTRL pressed
        db 'q'                  ; 0x15 Q pressed
        db '1'                  ; 0x16 1 pressed
        times 3 db 0
        db 'z'                  ; 0x1A Z pressed
        db 's'                  ; 0x1B S pressed
        db 'a'                  ; 0x1C A pressed
        db 'w'                  ; 0x1D W pressed
        db '2'                  ; 0x1E 2 pressed
        times 2 db 0
        db 'c'                  ; 0x21 C pressed
        db 'x'                  ; 0x22 X pressed
        db 'd'                  ; 0x23 D pressed
        db 'e'                  ; 0x24 E pressed
        db '4'                  ; 0x25 4 pressed
        db '3'                  ; 0x26 3 pressed
        times 2 db 0
        db ' '                  ; 0x29 SPACE pressed
        db 'v'                  ; 0x2A V pressed
        db 'f'                  ; 0x2B F pressed
        db 't'                  ; 0x2C T pressed
        db 'r'                  ; 0x2D R pressed
        db '5'                  ; 0x2E 5 pressed
        times 2 db 0
        db 'n'                  ; 0x31 N pressed
        db 'b'                  ; 0x32 B pressed
        db 'h'                  ; 0x33 H pressed
        db 'g'                  ; 0x34 G pressed
        db 'y'                  ; 0x35 Y pressed
        db '6'                  ; 0x36 6 pressed
        times 3 db 0
        db 'm'                  ; 0x3A M pressed
        db 'j'                  ; 0x3B J pressed
        db 'u'                  ; 0x3C U pressed
        db '7'                  ; 0x3D 7 pressed
        db '8'                  ; 0x3E 8 pressed
        times 2 db 0
        db ','                  ; 0x41 , pressed
        db 'k'                  ; 0x42 K pressed
        db 'i'                  ; 0x43 I pressed
        db 'o'                  ; 0x44 O pressed
        db '0'                  ; 0x45 0 pressed
        db '9'                  ; 0x46 9 pressed
        times 2 db 0
        db '.'                  ; 0x49 . pressed
        db '/'                  ; 0x4A / pressed
        db 'l'                  ; 0x4B L pressed
        db ';'                  ; 0x4C ; pressed
        db 'p'                  ; 0x4D P pressed
        db '-'                  ; 0x4E - pressed
        times 3 db 0
        db `'`                  ; 0x52 ' pressed
        db 0
        db '['                  ; 0x54 [ pressed
        db '='                  ; 0x55 = pressed
        times 2 db 0
        db 0                    ; 0x58 CAPSLOCK pressed
        db 0                    ; 0x59 RSHIFT pressed
        db `\n`                 ; 0x5A ENTER pressed
        db ']'                  ; 0x5B ] pressed
        db 0
        db `\\`                 ; 0x5D \ pressed
        times 8 db 0
        db `\b`                 ; 0x66 BACKSPACE pressed
        times 2 db 0
        db '1'                  ; 0x69 keypad 1 pressed
        db 0
        db '4'                  ; 0x6B keypad 4 pressed
        db '7'                  ; 0x6C keypad 7 pressed
        times 3 db 0
        db '0'                  ; 0x70 keypad 0 pressed
        db '.'                  ; 0x71 keypad . pressed
        db '2'                  ; 0x72 keypad 2 pressed
        db '5'                  ; 0x73 keypad 5 pressed
        db '6'                  ; 0x74 keypad 6 pressed
        db '8'                  ; 0x75 keypad 8 pressed
        db 0                    ; 0x76 keypad ESCAPE pressed
        db 0                    ; 0x77 keypad NUMLOCK pressed
        times 200 db 0

section .text
atkbd_init:
        call translation_off
        call scan_code_2
        mov long [continuation], discard
        call buffer
        mov [kbdbf], eax
	push MPICV+PS2V
	push isr
	call idt_set
	mov  long [esp], PS2V
	call i8259_unmask
	add  esp, 8
	ret

translation_off:
        call kbc_wait
        jc .ret
        mov al, 0x20
        out PS2C, al

        call kb_wait
        jc .ret
        in al, PS2D
        btr eax, CBTR
        mov ah, al

        call kbc_wait
        jc .ret
        mov al, 0x60
        out PS2C, al

        call kbc_wait
        jc .ret
        mov al, ah
        out PS2D, al
.ret:
        ret

scan_code_2:
        call kbc_wait
        jc .ret
        mov al, 0xF0
        out PS2D, al

        call kb_wait
        jc .ret
        in al, PS2D
        cmp al, 0xFA
        jne .ret

        call kbc_wait
        mov al, 0x00
        out PS2D, al

        call kb_wait
        in al, PS2D
        call kb_wait
        in al, PS2D
.ret:
        ret

reboot:
        call kbc_wait
        jc .ret
        mov al, 0xFE
        out PS2C, al
.ret:
        ret

;; Wait for data in port 0x60
;; OUT:
;; eflags#cf — 0 on success
;;             1 on timeout
kb_wait:
        mov ecx, 100000
.sp:
        in al, PS2C
        bt eax, SBOF
        jc .avail
        pause
        loop .sp
.timeout:
        stc
        ret
.avail:
        clc
        ret

;; Wait for port 0x64/0x60 availability
;; OUT:
;; eflags#cf — 0 on success
;;             1 on timeout
kbc_wait:
        mov ecx, 100000
.sp:
        in al, PS2C
        bt eax, SBIF
        jnc .avail
        pause
        loop .sp
.timeout:
        stc
        ret
.avail:
        clc
        ret

;; Keyboard interrupt handler
isr:
        cli
        pushad
        xor eax, eax
	in  al, PS2D
        call [continuation]
	mov  al, PIC_EOI
	out  MPICC, al
	out  SPICC, al
        popad
        sti
	iret

;; Keyboard interrupt handler continuations
discard:
        mov long [continuation], first_byte
        ret

first_byte:
        cmp eax, 0xE0
        je .discard
        cmp eax, 0xF0
        je .discard
        cmp eax, 0xE1
        je .discard
        cmp eax, 0xF1
        je .discard

        mov eax, [qwerty+eax]
        push eax
        mov eax, [kbdbf]
        push eax
        call pbbnb
        add esp, 8
        ret

.discard:
        mov long [continuation], discard
        ret
