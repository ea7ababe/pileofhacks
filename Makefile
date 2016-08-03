srcdir=src
objdir=build
CFLAGS=-O0 -Wall -std=gnu99 -ffreestanding

s_sources=$(wildcard $(srcdir)/*.s)
c_sources=$(wildcard $(srcdir)/*.c)

s_parts=$(patsubst $(srcdir)/%.s, $(objdir)/%.o, $(s_sources))
c_parts=$(patsubst $(srcdir)/%.c, $(objdir)/%.o, $(c_sources))
parts=$(s_parts) $(c_parts)

.PNONY: run-demo clean

demo-image.iso: $(objdir) lib.o
	echo "multiboot /kernel --test option; boot" \
		> $(objdir)/image/boot/grub/grub.cfg
	cc -c -o $(objdir)/simple-interpreter.o $(CFLAGS) \
		demos/simple-interpreter.c
	ld -T blueprint.ld -o $(objdir)/image/kernel \
		 lib.o $(objdir)/simple-interpreter.o
	grub-mkrescue -o $@ $(objdir)/image

lib.o: $(objdir) $(parts)
	ld -r -o $@ $(parts)

$(s_parts): $(objdir)/%.o : $(srcdir)/%.s
	nasm -f elf32 -I $(srcdir)/ $< -o $@

$(c_parts): $(objdir)/%.o : $(srcdir)/%.c
	cc -c $< -o $@ $(CFLAGS)

$(objdir):
	mkdir -p $(objdir)/image/boot/grub

run-demo: demo-image.iso
	rlwrap qemu-system-i386 -cdrom demo-image.iso \
		-boot d -monitor stdio
#run_efi: efi_image
#	rlwrap qemu-system-i386 -bios /usr/share/ovmf/ovmf_ia32.bin \
#		-drive file=efi_image,if=ide -monitor stdio -boot c

clean:
	rm -rf $(objdir) lib.o demo-image.iso
