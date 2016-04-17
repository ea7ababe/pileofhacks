;;; i8259: Intel 8259 programmable interrupt controller module
	global i8259_init
	global i8259_mask, i8259_unmask

	%include "def/i8259.s"

i8259_init:
	mov al, ICW1_INIT|ICW1_ICW4
	out MPICC, al		; ICW1: start initialization sequence
	out SPICC, al

	mov al, MPICV		; ICW2: master PIC vector offset
	out MPICD, al
	mov al, SPICV		; ICW2: slave PIC vector offset
	out SPICD, al

	mov al, 4		; ICW3: tell master pic about slave pic at IRQ2
	out MPICD, al
	mov al, 2		; ICW3: tell slave pic its cascade identity (2)
	out SPICD, al

	mov al, 1		; ICW4: 8086 mode
	out MPICD, al
	out SPICD, al

	mov al, 0xFF		; mask all interrupts
	out MPICD, al
	out SPICD, al

	sti			; enable external interrupts
	ret

;; Masks specified interrput
;; IN:
;; [esp+4] — 8 bit interrupt number
i8259_mask:
	mov cl, [esp+4]
	mov dx, 1
	shl dx, cl

	in  al, MPICD
	or  al, dl
	out MPICD, al

	in  al, SPICD
	or  al, dh
	out SPICD, al

	ret

;; Unmasks specified interrput
;; IN:
;; [esp+4] — 8 bit interrupt number
i8259_unmask:
	mov cl, [esp+4]
	mov dx, 1
	shl dx, cl
	not dx

	in  al, MPICD
	and al, dl
	out MPICD, al

	in  al, SPICD
	and al, dh
	out SPICD, al

	ret
