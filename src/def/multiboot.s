;;; Multiboot definitions

struc MBINFO
.flags: resd 1
.mem_lower: resd 1
.mem_upper: resd 1
.boot_device: resd 1
.cmdline: resd 1
.mods_count: resd 1
.mods_addr: resd 1
.syms: resd 4
.mmap_length: resd 1
.mmap_addr: resd 1
.drives_length: resd 1
.drives_addr: resd 1
.config_table: resd 1
.boot_loader_name: resd 1
.apm_table: resd 1
.vbe_control_info: resd 1
.vbe_mode_info: resd 1
.vbe_mode: resw 1
.vbe_interface_seg: resw 1
.vbe_interface_off: resw 1
.vbe_interface_len: resw 1
endstruc

%define MMEMAVAIL     (1<<0)
%define MBOOTDEVAVAIL (1<<1)
%define MCMDAVAIL     (1<<2)
%define MMODAVAIL     (1<<3)
%define MMAPAVAIL     (1<<6)
%define MDRIVESAVAIL  (1<<7)
%define MCONFAVAIL    (1<<8)
%define MLDNAMEAVAIL  (1<<9)
