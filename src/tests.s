;;; tests module
global tests

%include "def/memmgr.s"
%include "def/apic.s"
%include "def/i8259.s"

extern idt_set
extern puts
extern getchar
extern putchar
extern printf
extern trace
extern malloc
extern memcpy
extern strcpy
extern extend

extern start, break
extern kbdbf

section .data
        msg db `WO: %d, RO: %d, AD: %d \n`, 0
tests:
	enter 32, 0

        ; tests here

	leave
	ret
