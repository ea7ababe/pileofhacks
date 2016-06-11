;;; Peripheral Component Interconnect procedures
global pci_config
global pci_probe
global pci_class
global pci_devstr

;; Configuration registers:
%define CONFIG_ADDRESS 0xCF8
%define CONFIG_DATA 0xCFC

section .text
;; Get 32 bit PCI configuration register
;; IN:
;; [esp+4] — 8 bit bus number
;; [esp+8] — 8 bit slot number
;; [esp+12] — 8 bit function number
;; [esp+16] — 8 bit configuration offset
;; OUT:
;; eax — 32 bit configuration register value
pci_config:
        xor eax, eax
        mov al, [esp+4]
        shl eax, 16
        mov ah, [esp+8]
        shl ah, 3
        or ah, [esp+12]
        mov al, [esp+16]
        bts eax, 31

	mov dx, CONFIG_ADDRESS
	out dx, eax
        mov dx, CONFIG_DATA
	in eax, dx
	ret

;; Test if PCI device exists
;; IN:
;; [esp+4] — 8 bit bus number
;; [esp+8] — 8 bit device number
;; OUT:
;; eax — 0 if device does not exist
;;       1 otherwise
pci_probe:
	mov eax, [esp+4]
	mov ecx, [esp+8]
        mov edx, [esp+12]
	push 0
	push edx
	push ecx
	push eax
	call pci_config
	add esp, 16
        cmp ax, 0xFFFF
        je .no_device
        mov eax, 1
	ret
.no_device:
        xor eax, eax
        ret

;; Get PCI device class
;; IN:
;; [esp+4] — 8 bit bus number
;; [esp+8] — 8 bit device number
;; [esp+12] — 8 bit function number
;; OUT:
;; ah — 16 bit device class
;; al — 16 bit device subclass
pci_class:
	mov eax, [esp+4]
	mov ecx, [esp+8]
        mov edx, [esp+12]
	push 8h
	push edx
	push ecx
	push eax
	call pci_config
	add esp, 16
	shr eax, 16
	ret

;; Get PCI device description
;; IN:
;; [esp+4] — 16 bit device class and subclass
;;           (as returned by pci_class)
;; OUT:
;; eax — 32 bit pointer to ASCII string
section .data
ethernet_controller_device:
        db 'ethernet controller', 0
vga_controller_device:
        db 'VGA compatible controller', 0
host_bridge_device:
        db 'host bridge', 0
isa_bridge_device:
        db 'ISA bridge', 0
ide_controller_device:
        db 'IDE controller', 0
bridge_device:
        db 'bridge (yeah, just bridge, I dunno)', 0
unknown_device:
        db 'unknown device', 0
section .text
pci_devstr:
        mov ax, [esp+4]
        cmp ah, 1h
        je .storage_class
        cmp ah, 2h
        je .network_class
        cmp ah, 3h
        je .display_class
        cmp ah, 6h
        je .bridge_class
.unknown:
        mov eax, unknown_device
        ret
.storage_class:
        cmp al, 1h
        je .ide_controller_device
        jmp .unknown
.ide_controller_device:
        mov eax, ide_controller_device
        ret
.network_class:
        cmp al, 0
        je .ethernet_controller_device
        jmp .unknown
.ethernet_controller_device:
        mov eax, ethernet_controller_device
        ret
.display_class:
        cmp al, 0
        je .vga_controller_device
        jmp .unknown
.vga_controller_device:
        mov eax, vga_controller_device
        ret
.bridge_class:
        cmp al, 0
        je .host_bridge_device
        cmp al, 1
        je .isa_bridge_device
        cmp al, 80h
        je .bridge_device
        jmp .unknown
.host_bridge_device:
        mov eax, host_bridge_device
        ret
.isa_bridge_device:
        mov eax, isa_bridge_device
        ret
.bridge_device:
        mov eax, bridge_device
        ret
