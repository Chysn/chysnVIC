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
; IMPORTANT NOTE:
;    At least one popular assembler assembles the instruction
;        ADC $00FF,X
;    using the zeropage,X addressing mode, even though the leading zeroes
;    should make absolute,X explicit. If the installer crashes your system,
;    check that.
;
* = $1800
H_IRQ   = $EABF         ; This is the default hardware IRQ
SCRPAD  = $03           ; Scratchpad memory for self-modifying code location    
IRQV    = $0314         ; Hardware IRQ vector

START:  PHP
        SEI

        LDA SCRPAD      ; Save these scratchpad values so that this start
        PHA             ; routine is as neutral to its environment as possible
        LDA SCRPAD + 1
        PHA
        
        JSR $FFED       ; This is the KERNAL routine SCREEN, which only
                        ; sets the X and Y registers. It's called only to
                        ; add a return address to the stack, which will be
                        ; used to set the location of the IRQ handler.
                        
        TSX             ; Interrupts are conveniently off, so we can be sure that the
                        ; ending address of the above JSR is still in the same place.
                        ; So we're going to raid the stack to determine where this
                        ; routine is located. Since the value was pulled by the RTS,
                        ; note how the stack memory reference is offset below...  
        
        CLC
        LDA #$36        ; The CHAIN vector is 54 ($36) bytes after the JSR,
        ADC $00FF,X     ; so add 54 to the low byte of the return address and
        STA SCRPAD      ; stash it for safekeeping.
        LDA #$00        ; The high byte is only going to change if the
        ADC $0100,X     ; carry flag is set from the previous ADC
        STA SCRPAD + 1
        
        LDY #$00        ; The idea here is that multiple IRQ routines can be
        LDA IRQV        ; installed into memory, with each one "chaining" to
        STA (SCRPAD),Y  ; the next. This block of code looks up the current IRQ
        LDA IRQV + 1    ; location, and sets it as the location of the JMP
        INY             ; at the CHAIN label, below. So your handler should branch to
        STA (SCRPAD),Y  ; CHAIN when it's finished. Theoretically, it will eventually
                        ; wind up at the hardware default IRQ handler at $EABF.
        
        CLC             ; Then, we set the IRQ vector to the new handler,
        LDA #$02        ; which is two bytes after CHAIN's JMP operand, whose
        ADC SCRPAD      ; address is still in the scatchpad locations.
        STA IRQV        ; Set the low byte to the new place
        LDA #$00        ; The high byte will be the same as it was before
        ADC SCRPAD + 1  ; unless the carry flag was set in the previous ADC
        STA IRQV + 1
        
        PLA             ; Restore the scratchpad values as a courtesy to the universe
        STA SCRPAD + 1
        PLA
        STA SCRPAD

        PLP
        RTS
        
CHAIN:  JMP H_IRQ;      ; Defaults to the hardware IRQ, but it may be different
                        ; if multiple IRQ handlers are loaded with this method
        
HANDLE: INC $900F       ; This is a demo, and we have to do SOMETHING, so just change
                        ; the screen color. Your real IRQ handler would go here.
        CLC
        BCC CHAIN       ; Unconditional branch back to wherever the IRQ handler
                        ; was before.
