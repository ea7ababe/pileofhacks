;;; Memory management unit definitions
extern PROGSIZE
%define KTEXT0 0x00100000	; kernel text segment virtual offset
%define KHEAP0 0x0010A000	; kernel heap virtual offset
%define BI2BY  8		; bits per byte
%define BI2WD  32		; bits per word
%define BY2WD  4		; bytes per word
%define PGSIZE 400000h		; page size (4MiB for now)
%define PDSIZE 1000h		; page directory size
%define PDESZ  4                ; page directory entry size in bytes

;;; Page directory and page tables

;; Page directory entry format
;; +31-------------12+11----9+8---------------0+
;; |page table offset|ignored|G|S|0|A|D|W|U|R|P|
;; +--------20-------+---3---+--------9--------+
;;
;; G - place an entry to the global translation lookaside buffer
;; S - page size: if set than page is 4MB, otherwise it is 4KB.
;; A - accessed: this bit is set by the CPU when the page is accessed.
;; D - cache disable bit: if set the page will not be cached.
;; W - write-through: if the bit is set, write-through caching is enabled
;;                    if not, then write-back is enabled instead.
;; U - user bit: if set, then the page can be accessed by all
;;               otherwise only supervisor can access it.
;; R - read/write: if set, the page is read/write,
;;                 otherwise it is read-only
;; P - present: the page is in physical memory
;;              if the page, for example, swaped out,
;;              this bit should be 0.
%define PDPR (1<<0)
%define PDRW (1<<1)
%define PDUS (1<<2)
%define PDWT (1<<3)
%define PDCD (1<<4)
%define PDAC (1<<5)
%define PDSZ (1<<7)
%define PDGL (1<<8)

;; Page table entry format
;; +31----------------12+11----9+8---------------0+
;; |physical page offset|ignored|G|0|D|A|C|W|U|R|P|
;; +---------20---------+---3---+--------9--------+
;;
;; G - global flag: prevents TLB from updating the address in it's
;;                  cache if CR3 is reset the page global enable bit
;;                  in CR4 must be set to enable this feature
;; D - dirty flag: if set, then the page has been written to;
;;                 this flag is not updated by the CPU, and
;;                 once set will not unset itself


;; CR4 flags
%define CR4PSE (1<<4)		; 4MiB pages enabled
%define CR4GL  (1<<7)		; global pages enabled

;; CR3 flags
%define CR3PE (1<<31)		; paging enabled
