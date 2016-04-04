;;; unsorted macros and definitions

;; return if zero
%macro retz 0
        jnz %%skip
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
%macro lcs 1
        jmp %1:%%newcs
        %%newcs
%endmacro
