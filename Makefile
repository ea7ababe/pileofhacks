srcdir=src
objdir=build
s_sources=$(wildcard $(srcdir)/*.s)
c_sources=$(wildcard $(srcdir)/*.c)
s_parts=$(patsubst $(srcdir)/%.s, $(objdir)/%.o, $(s_sources))
c_parts=$(patsubst $(srcdir)/%.c, $(objdir)/%.o, $(c_sources))
parts=$(s_parts) $(c_parts)

image.iso: $(objdir) $(parts)
	mkdir -p $(objdir)/image/boot/grub
	echo "multiboot /kernel --test option; boot" > $(objdir)/image/boot/grub/grub.cfg
	i686-elf-gcc -T $(srcdir)/blueprint.ld -o $(objdir)/image/kernel -ffreestanding -O2 -nostdlib $(parts)
	grub-mkrescue -o $@ $(objdir)/image

$(s_parts): $(objdir)/%.o : $(srcdir)/%.s
	nasm -f elf32 -I $(srcdir)/ $< -o $@

$(c_parts): $(objdir)/%.o : $(srcdir)/%.c
	i686-elf-gcc -c $< -o $@ -std=gnu99 -ffreestanding -O2 -Wall

$(objdir):
	mkdir -p $(objdir)

.PHONY: run
run: image.iso
	rlwrap qemu-system-i386 -cdrom image.iso -boot d -monitor stdio

.PHONY: clean
clean:
	rm -rf $(objdir)
