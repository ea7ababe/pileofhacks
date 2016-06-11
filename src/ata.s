;;; ATA driver (DMA mode only)

section .bss
alignb 32
;; physical region descriptor table
        PRDT resd 2*64
        bf resb 0xFFFF

section .text
