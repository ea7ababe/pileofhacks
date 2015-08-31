### i8259: Intel 8259 programmable interrupt controller module
	.global i8259_init
	.global i8259_mask, i8259_unmask

	.include "def/i8259.s"

i8259_init:
	mov $ICW1_INIT|ICW1_ICW4, %al
	out %al, $MPICC		# ICW1: start initialization sequence
	out %al, $SPICC

	mov $MPICV, %al		# ICW2: master PIC vector offset
	out %al, $MPICD
	mov $SPICV, %al		# ICW2: slave PIC vector offset
	out %al, $SPICD

	mov $4, %al		# ICW3: tell master pic about slave pic at IRQ2
	out %al, $MPICD
	mov $2, %al		# ICW3: tell slave pic its cascade identity (2)
	out %al, $SPICD

	mov $1, %al		# ICW4: 8086 mode
	out %al, $MPICD
	out %al, $SPICD

	mov $0xFF, %al		# mask all interrupts
	out %al, $MPICD
	out %al, $SPICD

	sti			# enable external interrupts
	ret

	## irq_no -> IO
i8259_mask:
	mov 4(%esp), %cl
	mov $1, %dx
	shl %cl, %dx
	
	in $MPICD, %al
	or %dl, %al
	out %al, $MPICD

	in $SPICD, %al
	or %dh, %al
	out %al, $SPICD

	ret

	## irq_no -> IO
i8259_unmask:
	mov 4(%esp), %cl
	mov $1, %dx
	shl %cl, %dx
	not %dx

	in $MPICD, %al
	and %dl, %al
	out %al, $MPICD

	in $SPICD, %al
	and %dh, %al
	out %al, $SPICD

	ret
