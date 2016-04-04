;;; programmable interrupt timer

global pit_init

%define PITD0 40h
%define PITD1 41h
%define PITD2 42h
%define PITMC 43h

%include "def/i8259.s"

extern i8259_unmask
extern idt_set

section .text
pit_init:
        push MPICV
        push empty_isr
        call idt_set
        mov long [esp], 0
        call i8259_unmask
        add esp, 8

        mov al, 00110110b
        out PITMC, al
        mov ax, 1193180/100
        out PITD0, al
        shr ax, 8
        out PITD0, al

        ret

empty_isr:
        i8259_eoi
        iret
