;;;; i8259 shared definitions
	; ports
	MPICC equ 0x20  	; master pic command port
	MPICD equ 0x21		; master equ data
	SPICC equ 0xA0		; slave equ command
	SPICD equ 0xA1		; slave equ data
	EOI equ 0x20		; end of interrupt command

	; commands
	PIC_EOI equ 0x20

	; IDT offsets
	MPICV equ 0x20		; for master
	SPICV equ 0x28		; for slave

	; PIC initialization control words
	ICW1_ICW4 equ 1		; ICW4 needed
	ICW1_SINGLE equ 2	; Single mode (not cascade)
	ICW1_I4 equ 4		; Call address interval 4 (not 8)
	ICW1_LEVEL equ 8	; Level triggered mode
	ICW1_INIT equ 16	; Initialization command

	ICW4_8086 equ 1		; 8086/88 (MCS-80/85) mode
	ICW4_AUTO equ 2		; Auto (normal) EOI
	ICW4_SBF equ 4		; Buffered mode/slave
	ICW4_MBF equ 8		; Buffered mode/master
	ICW4_SFNM equ 16	; Special fully nested mode

%macro i8259_eoi 0
	mov al, PIC_EOI
	out MPICC, al
%endmacro
