;;; Memory management unit definitions
%define KZERO  0xC0000000	; kernel virtual offset
%define KTEXT0 0xC0100000	; kernel text segment virtual offset
%define KHEAP0 0xC010A000	; kernel heap virtual offset
%define	BI2BY		8	; bits per byte
%define	BI2WD		32	; bits per word
%define	BY2WD		4	; bytes per word


;;; Page directory and page tables

;; Page directory entry format
;; +31-------------12+11----9+8---------------0+
;; |page table offset|ignored|G|S|0|A|D|W|U|R|P|
;; +--------20-------+---3---+--------9--------+
;;
;; G - translation is global. Just ignore...
;; S - page size: if set than page is 4MB, otherwise it is 4KB.
;; A - accessed: this bit is set by the CPU when the page is accessed.
;; D - cache disable bit: if set the page will not be cached.
;; W - write-through: if the bit is set, write-through caching is enabled
;;                    if not, then write-back is enabled instead.
;; U - user bit: if set, then the page can be accessed by all
;;               otherwise only supervisor can access it.
;; R - read/write: if set, the page is read/write, otherwise it is read-only
;; P - present: the page is in physical memory
;;              if the page, for example, swaped out, this bit should be 0.
	
;; Page table entry format
;; +31----------------12+11----9+8---------------0+
;; |physical page offset|ignored|G|0|D|A|C|W|U|R|P|
;; +---------20---------+---3---+--------9--------+
;;
;; G - global flag: prevents TLB from updating the address in it's cache if CR3 is reset
;;                  the page global enable bit in CR4 must be set to enable this feature
;; D - dirty flag: if set, then the page has been written to
;;                 this flag is not updated by the CPU, and once set will not unset itself
