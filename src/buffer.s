;;; All you need for interprocess communication

global make_buffer

%include "def/taskmgr.s"

section .text
make_buffer:

	; GETS:
	; [esp+4] — pointer to buffer descriptor
	;
read_buffer:

write_buffer:
