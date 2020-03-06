; Monophonic IRQ Song Player for Commodore VIC-20
; (c)2020, Jason Justian
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

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