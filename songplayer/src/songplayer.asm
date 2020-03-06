* = $1770

DATA   = $1900
PTR    = $04
COUNT  = $03
IRQ    = $EABF
VOICE  = $900B

START:  PHP
        SEI
        LDA #<PLAY        ; Set the interrupt code
        STA $0314
        LDA #>PLAY
        STA $0315
        JSR RESET
        PLP
        RTS

PLAY:   LDX COUNT
        BEQ NEXT
        DEX
        STX COUNT
RETURN: JMP IRQ
        
NEXT:   LDY #$00
        LDA ($04),Y     ; This is the note
        BNE NOTEPL
        JSR RESET       ; A note value of 0 resets the position
        LDA ($04),Y     ; Try again after reset
NOTEPL: STA $900B
        INY
        LDA ($04),Y     ; This is the duration
        STA COUNT
PLUS1:  INC $04         ; Increment the counter twice for note and duration
        BNE PLUS2
        INC $05
PLUS2:  INC $04
        BNE RETURN
        INC $05
        CLC
        BCC RETURN

RESET:  LDA #<DATA      ; Reset the data counter
        STA PTR
        LDA #>DATA
        STA PTR + 1
        LDA #$00        ; Reset the duration counter
        STA COUNT
        RTS