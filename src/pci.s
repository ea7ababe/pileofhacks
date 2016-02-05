;;; Peripheral Component Interconnect procedures
global read_pci_config
global pci_device_exists_p
global get_pci_device_class
	
;; Configuration registers:
%define CONFIG_ADDRESS 0xCF8
%define CONFIG_DATA 0xCFC

section .text
	; (bus, slot, func, offset const uint8) -> (config uint32)
read_pci_config:
	mov eax, [esp+16]
	mov ecx, [esp+12]
	mov esi, [esp+8]
	mov edi, [esp+4]

	shl ecx, 8
	shl esi, 11
	shl edi, 16

	or eax, ecx
	or eax, esi
	or eax, edi
	or eax, 0x80000000

	mov edx, CONFIG_ADDRESS
	out dx, eax
	in eax, dx

	ret

	; (bus, slot const uint8) -> (existence uint8)
	; existence = 0 if device doesn't exist
	; existence != 0 if device exists
pci_device_exists_p:
	mov eax, [esp+4]
	mov ecx, [esp+8]
	push 0
	push 0
	push ecx
	push eax
	call read_pci_config
	add esp, 16

	xor ax, 0xFFFF
	ret

	; (bus, slot const uint8) -> (device_class uint16)
	; ah: device class
	; al: device subclass
get_pci_device_class:
	mov eax, [esp+4]
	mov ecx, [esp+8]
	push 8h
	push 0
	push ecx
	push eax
	call read_pci_config
	add esp, 16
	shr eax, 16
	ret

	; (bus, slot const uint8) -> (bus_number uint8)
secondary_pci_bus_number:
	mov eax, [esp+4]
	mov ecx, [esp+8]
	push 18h
	push 0
	push ecx
	push eax
	call read_pci_config
	add esp, 16
	shr eax, 8
	ret
