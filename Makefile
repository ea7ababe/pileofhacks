srcdir=src
objdir=build

s_sources=$(wildcard $(srcdir)/*.s)
c_sources=$(wildcard $(srcdir)/*.c)

s_parts=$(patsubst $(srcdir)/%.s, $(objdir)/%.o, $(s_sources))
c_parts=$(patsubst $(srcdir)/%.c, $(objdir)/%.o, $(c_sources))
parts=$(s_parts) $(c_parts)

.PNONY: run run_efi clean

efi_image: $(objdir) $(parts)
	i686-w64-mingw32-ld -T $(srcdir)/blueprint.ld \
		-o $(objdir)/efi-image/efi/boot/bootia32.efi \
		-dll --format=elf32-i386 --oformat=pei-i386 \
		--subsystem 10 $(parts)
	dd if=/dev/zero of=$@ bs=512 count=93717
	parted ./$@ -s -a minimal mklabel gpt
	parted ./$@ -s -a minimal mkpart EFI FAT16 2048s 93683s
	parted ./$@ -s -a minimal toggle 1 boot
	dd if=/dev/zero of=$(objdir)/efi-image/part.fat bs=512 count=91635
	mformat -i $(objdir)/efi-image/part.fat -h 32 -t 32 -n 64 -c 1
	mcopy -s -i $(objdir)/efi-image/part.fat $(objdir)/efi-image/efi '::/'
	dd if=$(objdir)/efi-image/part.fat of=$@ bs=512 seek=2048 conv=notrunc

image.iso: $(objdir) $(parts)
	echo "multiboot /kernel --test option; boot" > $(objdir)/image/boot/grub/grub.cfg
	i686-elf-ld -T $(srcdir)/blueprint.ld -o $(objdir)/image/kernel $(parts)
	grub-mkrescue -o $@ $(objdir)/image

$(s_parts): $(objdir)/%.o : $(srcdir)/%.s
	nasm -f elf32 -I $(srcdir)/ $< -o $@

$(c_parts): $(objdir)/%.o : $(srcdir)/%.c
	i686-elf-gcc -c $< -o $@ -std=gnu99 -ffreestanding -O2 -Wall

$(objdir):
	mkdir -p $(objdir)/image/boot/grub
	mkdir -p $(objdir)/efi-image/efi/boot/

run: image.iso
	rlwrap qemu-system-i386 -cdrom image.iso -boot d -monitor stdio
run_efi: efi_image
	rlwrap qemu-system-i386 -bios /usr/share/ovmf/ovmf_ia32.bin \
		-drive file=efi_image,if=ide -monitor stdio -boot c

clean:
	rm -rf $(objdir)
