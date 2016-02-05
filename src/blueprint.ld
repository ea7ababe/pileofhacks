ENTRY(_start)

SECTIONS {
  . = 0x100000;
  .boot BLOCK(4K) : {
    *(.multiboot)
    *(.boot)
  }

  . += 0xC0000000;
  
  .text BLOCK(4K) : AT(ADDR(.text)-0xC0000000) {
    *(.text)
  }

  .data BLOCK(4K) : AT(ADDR(.data)-0xC0000000) {
    *(.data)
  }

  .rodata BLOCK(4K) : AT(ADDR(.rodata)-0xC0000000) {
    *(.rodata)
  }

  .bss BLOCK(4K) : AT(ADDR(.bss)-0xC0000000) {
    *(COMMON)
    *(.bss)
    *(.call_stack)
  }

  HEAP0 = .;
}
