;;; Global descriptor table definitions
	
;; GDT header format
;; +0---15+16----31+ 6 bytes
;; | size | offset |
;; +------+--------+

;; GDT entry format
;; +0-------15+16-----31+32------39+40-------47+48-------51+52-55+56------63+ 8 bytes
;; |limit 0:15|base 0:15|base 16:23|access byte|limit 16:19|flags|base 24:31|
;; +----------+---------+----------+-----------+-----------+-----+----------+
;;     	16     	   16  	      8	       	 8     	     4 	      4	       8

;; GDT entry access byte
%define GDT_Pr 0b10000000	; present bit
%define GDT_P1 0b00100000	; privilege level 1
%define GDT_P2 0b01000000	; privilege level 2
%define GDT_P3 0b01100000	; privilege level 3
%define GDT_Dt 0b00010000	; descriptor type (0 = system, 1 = code/data)
%define GDT_Ex 0b00001000	; executable bit
%define GDT_Dn 0b00000100
	; Ex=0: direction bit
	; (segment grows down: the offset has to be larger than limit)
%define GDT_Cf 0b00000100
	; Ex=1: confirming bit
	; (code can be executed from lower privilege level)
%define GDT_W  0b00000010	; Ex=0: data segment is writable
%define GDT_R  0b00000010	; Ex=1: executable segment is readable
%define GDT_Ac 0b00000001	; access bit ?_?

;; GDT entry flags
%define GDT_Gr 0b10000000
	; granularity bit
	; if 0 the "limit" field is in 1B blocks
	; if 1 the "limit" field is in 4kB blocks
%define GDT_Sz 0b01000000
	; size bit (1 for 32 bit mode, 0 for 16 bit mode)
	; it defines the size of the stack cells


;;; Task state segment (already forgot why were I need it)
;; Task state segment entry format
;; +0-15+16----31+32-63+64-79+80-95+96-127+128-143+144--159+160--191+
;; |LINK|RESERVED|ESP0 |SS0  |RSRVD|ESP1  |SS1    |RESERVED|ESP2    |
;; +----+--------+-----+-----+-----+------+-------+--------+--------+
;; +192-207+208--223+224-255+256-287+288-319+320-351+352-383+384-415+
;; |SS2    |RESERVED|CR3    |EIP    |EFLAGS |EAX    |ECX    |EDX    |
;; +-------+--------+-------+-------+-------+-------+-------+-------+
;; +416-447+448-479+480-511+512-543+544-575+576-591+592--607+608-623+
;; |EBX    |ESP    |EBP    |ESI    |EDI    |ES     |RESERVED|CS     |
;; +-------+-------+-------+-------+-------+-------+--------+-------+
;; +624--639+640-655+656--671+672-687+688--703+704-719+720-------735+
;; |RESERVED|SS     |RESERVED|DS     |RESERVED|FS     |RESERVED     |
;; +--------+-------+--------+-------+--------+-------+-------------+
;; +736-751+752--767+768-783+784--815+816-----831+
;; |GS     |RESERVED|LDTR   |RESERVED|IOBP offset| 104 bytes
;; +-------+--------+-------+--------+-----------+

