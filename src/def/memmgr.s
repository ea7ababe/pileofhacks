;;; Memory allocator definitions
%define MAMDSZ 8                ; minimal data size
%define MAAF 111b               ; all flags set (for use with and)
%define MANF ~MAAF              ; no flags set

;; flag bits
%define MAUSED 0                ; indicates that the sector is used
%define MAEND  1                ; indicates that the sector is the last

;; memory section header
struc Memhdr
.prhd: resd 1		; previous header pointer
.data: resd 1		; data size and flags
.size:
endstruc
