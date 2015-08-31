### i8259 shared definitions
	## ports
	.set MPICC, 0x20	# master pic command port
	.set MPICD, 0x21	# master, data
	.set SPICC, 0xA0	# slave, command
	.set SPICD, 0xA1	# slave, data
	.set EOI, 0x20		# end of interrupt command

	## commands
	.set PIC_EOI, 0x20

	## IDT offsets
	.set MPICV, 0x20	# for master
	.set SPICV, 0x28	# for slave

	## PIC initialization control words
	.set ICW1_ICW4, 1	# ICW4 needed
	.set ICW1_SINGLE, 2	# Single mode (not cascade)
	.set ICW1_I4, 4		# Call address interval 4 (not 8)
	.set ICW1_LEVEL, 8	# Level triggered mode
	.set ICW1_INIT, 16	# Initialization command

	.set ICW4_8086, 1	# 8086/88 (MCS-80/85) mode
	.set ICW4_AUTO, 2	# Auto (normal) EOI
	.set ICW4_SBF, 4	# Buffered mode/slave
	.set ICW4_MBF, 8	# Buffered mode/master
	.set ICW4_SFNM, 16	# Special fully nested mode
