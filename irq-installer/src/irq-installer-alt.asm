; IRQ Installer
; Jason Justian
;
; This program sets the IRQ Vector, but has a couple cool features
; that make it very flexible for some situations. Specifically:
;
; 1) It plays nicely with other IRQ handler routines
;
;    It looks up the current IRQ vector and provides a relative branch
;    back to that handler. This way, multiple IRQ handlers can be loaded
;    into memory and run sequentially in the opposite order in which
;    they were installed.
;
; 2) It is fully position-independent
;
;    It determines where it is in memory and sets the IRQ vector
;    accordingly. The IRQ Installer can be placed anywhere in RAM,
;    as long as you use relative branching within your code,
;    and end with (for example)
;        BCC
;        BCC CHAIN
;
* = $1800
H_IRQ   = $EABF         ; This is the default hardware IRQ
SCRPAD  = $69           ; Scratchpad memory for self-modifying code location    
IRQV    = $0314         ; Hardware IRQ vector

START:  PHP
        SEI

        LDY #$68        ; Loads routine into FAC2 to populate X with the low
        STY $69         ; byte and Y with the high byte of the last byte of
        STY $6B         ; the address of the JSR below.
        LDY #$AA        ;
        STY $6A         ; 0069 PLA
        LDY #$A8        ; 006A TAX
        STY $6C         ; 006B PLA
        LDY #$48        ; 006C TAY
        STY $6D         ; 006D PHA
        STY $6F         ; 006E TXA
        LDY #$8A        ; 006F PHA
        STY $6E         ; 0070 RTS
        LDY #$60
        STY $70
        JSR $0069

        CLC
        ADC #$2A        ; The CHAIN vector is 42 ($2A) bytes after the JSR,
        STA SCRPAD      ; so add 42 to the low byte of the return address
        TYA
        ADC #$00        ; The high byte is only going to change if the
        STA SCRPAD + 1  ; carry flag was set with ADC #$2D above

        LDY #$00        ; The idea here is that multple IRA routines can be
        LDA IRQV        ; installed into memory, with each one "chaining" to
        STA (SCRPAD),Y  ; the next. This block of code looks up the current IRQ
        INY             ; location, and sets it as the location of the JMP
        LDA IRQV + 1    ; at the CHAIN label below. Your handler should branch to
        STA (SCRPAD),Y  ; CHAIN when it's finished.

        CLC             ; Then, we set the IRQ vector to the new handler,
        LDA SCRPAD      ; which is two bytes after CHAIN's JMP operand, whose 
        ADC #$02        ; address is still in the scratchpad locations.
        STA IRQV        ; Set the low byte of the new handler
        LDA SCRPAD + 1
        ADC #$00        ; The high byte will be the same as it was before
        STA IRQV + 1    ; unless the carry flag was set by ADC #$02

        PLP
        RTS

CHAIN:  JMP H_IRQ;      ; Defaults to the hardware IRQ, but it may be different
                        ; if multiple IRQ handlers are loaded with this method

HANDLE: INC $900F       ; This is a demo, and we have to do SOMETHING, so just change
                        ; the screen color. Your real IRQ handler would go here.
        CLC
        BCC CHAIN       ; Unconditional branch back to wherever the IRQ handler
                        ; was before.
