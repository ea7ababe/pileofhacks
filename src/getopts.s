### Multiboot information structure
	## bits name        presence
	## -------------------------
	## 0    flags       required
	## 4    mem_lower   if flags[0] is set
	## 8    mem_upper   if flags[0] is set
	## 12   boot_device if flags[1] is set
	## 16   cmdline     if flags[2] is set
	## 20   mods_count  if flags[3] is set
	## 24   mods_addr   if flags[3] is set
	## 28   syms        if flags[4] of flags[5] is set
	## 44   mmap_length if flags[6] is set
	## 48   mmap_addr   if flags[6] is set
	## -------------------------
	## 52:86 — other stuff (see multiboot specification)

	## flags contains information about available options
	## mem_lower contains available memory size below 1MiB in kilobytes (max 640kB(625KiB) ?_?)
	## mem_upper contains available memory size starting from 1MiB to the first gap
	## cmdline contains address to the program options 0-terminated string
	## mmap_length contains size of memory map buffer
	## mmap_addr contains address to memory map buffer

	## mmap entry:
	## bits name      description
	## 0    size      size of the entry
	## 4    base_addr base address of the memory region
	## 12   length    length of the memory region in bytes
	## 20   type      type of the memory region (1 for RAM)

	.section .text
	## TO BE CONTINUED...
