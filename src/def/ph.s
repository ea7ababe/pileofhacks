;;; unsorted macros and definitions

;; return if zero
%macro retc 1
        j%1 %%skip
        ret
        %%skip:
%endmacro
%macro retz 0
        jnz %%skip
        ret
        %%skip:
%endmacro
%macro retz 1
        jnz %%skip
        mov eax, %1
        ret
        %%skip:
%endmacro

;; return from interrupt if zero
%macro iretz 0
        jnz %%skip
        iret
        %%skip:
%endmacro

;; load code segment
%macro ldcs 1
        jmp %1:%%newcs
        %%newcs
%endmacro
