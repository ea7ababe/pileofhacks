SECTIONS {
  POFFSET = 0x00100000;
  VOFFSET = 0xC0000000;
  
  . = POFFSET;
  .boot BLOCK(4K) : {
    *(.multiboot)
    *(.boot)
  }

  . += VOFFSET;
  
  .text BLOCK(4K) : AT(ADDR(.text)-VOFFSET) {
    *(.text)
  }

  .data BLOCK(4K) : AT(ADDR(.data)-VOFFSET) {
    *(.data)
  }

  .rodata BLOCK(4K) : AT(ADDR(.rodata)-VOFFSET) {
    *(.rodata)
  }

  .bss BLOCK(4K) : AT(ADDR(.bss)-VOFFSET) {
    *(COMMON)
    *(.bss)
    *(.call_stack)
  }
}
