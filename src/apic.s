;;; Advaced Programmable Interupt Controller

global apic_present_p
global rdapic
global wrapic

%include "def/apic.s"

section .text
        ; Test for local APIC presence
        ; OUT:
        ; eax — 1 means APIC is present, 0 otherwise
apic_present_p:
        mov eax, 1
        cpuid
        and edx, (1<<CPUID_APIC)
        mov eax, edx
        shr eax, CPUID_APIC
        ret

        ; Read form local APIC register
        ; IN:
        ; [esp+4] — register offset
        ; OUT:
        ; eax — register value
rdapic:
        mov eax, [esp+4]
        add eax, APIC
        mov eax, [eax]
        ret

        ; Write to local APIC register
        ; IN:
        ; [esp+4] — register offset
        ; [esp+8] — new register value
wrapic:
        mov eax, [esp+4]
        add eax, APIC
        mov ecx, [esp+8]
        mov [eax], ecx
        ret
