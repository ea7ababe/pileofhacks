# Pile of hacks

This is a  C programming language library  for unikernels development.
Right now it  is only available for IA-32 architecture  and is written
in netwide assembler.

There is not much right now, but I'm trying to add stuff as often as I
can.

## Building

To build the library you need GNU  C compiler, linker and make (or any
other compatible program). If you have them just run...

    $ make lib.o

...in the project root directory.

## Demos

There is a simple command interpreter located in `demos` subdirectory
as `simple-interpreter.c`. To build it run...

    $ make test-image.iso

...in the project root directory. To do it you must also have GNU GRUB
installed. There will be created  a `kernel` in multiboot format under
`build/image`  and then  packed into  `test-image.iso` file  with GRUB
bootloader.
