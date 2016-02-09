;;; Memory allocator definitions
%define MAMDSIZE 8
%define MAFLAGS  111b
%define MAUSED  (1<<0)
%define MAEOM   (1<<1)

struc Memhdr
.prhd: resd 1		; previous header pointer
.data: resd 1		; section size and flags
.size:
endstruc
