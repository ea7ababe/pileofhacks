ENTRY(_start)

SECTIONS {
  . = 0x100000;
  .boot BLOCK(4K) : {
    *(.multiboot)
    *(.boot)
  }
  
  .text BLOCK(4K) : AT(ADDR(.text)) {
    *(.text)
  }

  .data BLOCK(4K) : AT(ADDR(.data)) {
    *(.data)
  }

  .rodata BLOCK(4K) : AT(ADDR(.rodata)) {
    *(.rodata)
  }

  .bss BLOCK(4K) : AT(ADDR(.bss)) {
    *(COMMON)
    *(.bss)
    *(.call_stack)
  }

  ksize = .;
}
