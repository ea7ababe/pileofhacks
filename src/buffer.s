;;; Circular buffers

;; Design:
;; | header (8B) | data (4096B) |
;; header:
;; | writer offset (4B) | available data size for readers (4B) |

global buffer
global getbb
global pbbnb, pdwbnb

%define DSIZE 1000h
struc Buffer
.wo: resd 1
.ro: resd 1
.ad: resd 1
.data: resb DSIZE
.size:
endstruc

extern malloc
extern trace
extern errno

section .text
;; Make a new buffer
;; OUT:
;; eax — 32 bit pointer to the buffer
buffer:
        push Buffer.size
        call malloc
        mov long [eax+Buffer.wo], 0
        mov long [eax+Buffer.ro], 0
        mov long [eax+Buffer.ad], 0
        add esp, 4
        ret

;; Get byte from a buffer
;; IN:
;; [esp+4] — 32 bit buffer address
;; OUT:
;; al — 8 bit value
getbb:
        push esi
        mov esi, [esp+8]
.wait:
        pause
        mov eax, [esi+Buffer.ad]
        test eax, eax
        jz .wait
        dec eax
        mov [esi+Buffer.ad], eax
        mov eax, [esi+Buffer.ro]
        xor edx, edx
        mov ecx, DSIZE
        inc eax
        div ecx
        mov [esi+Buffer.ro], edx
        mov al, [esi+Buffer.data+edx]
        pop esi
        ret

;; Put byte in a buffer (non blocking)
;; IN:
;; [esp+4] — 32 bit buffer address
;; [esp+8] — 8 bit value to put into the buffer
;; OUT:
;; [errno] —  0 on success
;;           -1 on failure
pbbnb:
        push esi
        mov esi, [esp+8]
        mov eax, [esi+Buffer.ad]
        mov ecx, DSIZE
        inc eax
        cmp eax, ecx
        jge .fail
        mov [esi+Buffer.ad], eax
        mov eax, [esi+Buffer.wo]
        xor edx, edx
        inc eax
        div ecx
        mov [esi+Buffer.wo], edx
        mov al, [esp+12]
        mov [esi+Buffer.data+edx], al
        pop esi
        mov long [errno], 0
        ret
.fail:
        pop esi
        mov long [errno], -1
        ret

;; Put double word in a buffer (non blocking)
;; IN:
;; [esp+4] — 32 bit buffer address
;; [esp+8] — 32 bit value to put into the buffer
;; OUT:
;; [errno] —  0 on success
;;           -1 on failure
pdwbnb:
        push esi
        mov esi, [esp+8]
        mov eax, [esi+Buffer.ad]
        mov ecx, DSIZE
        add eax, 4
        cmp eax, ecx
        jge .fail
        mov [esi+Buffer.ad], eax
        mov eax, [esi+Buffer.wo]
        xor edx, edx
        div ecx
        mov eax, [esp+12]
        mov [esi+Buffer.data+edx], eax
        mov long [errno], 0
        ret
.fail:
        mov long [errno], -1
        ret
