;;; Advanced Programmable Interrupt Controller definitions

%define APIC 0FEE00000h
%define APIC_ID  (APIC+20h)
%define APIC_VR  (APIC+30h)
%define APIC_TPR (APIC+80h)
%define APIC_APR (APIC+90h)
%define APIC_PPR (APIC+0A0h)
%define APIC_EOI (APIC+0B0h)
%define APIC_RRD (APIC+0C0h)
%define APIC_LDR (APIC+0D0h)
%define APIC_DFR (APIC+0E0h)
%define APIC_SIV (APIC+0F0h)

%define APIC_LVT_ICRL (APIC+300h)
%define APIC_LVT_ICRH (APIC+310h)
%define APIC_LVT_TR   (APIC+320h)
