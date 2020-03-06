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

DATA   = $1900          ; Starting point for the song
                        ; Each note in the song is represented by a data word.
                        ; The first byte is the note, the next byte is the duration
                        ; of that note in jiffies (1/60th sec.).
                        ; After that duration has elapsed, the player moves to the
                        ; next data word.
                        ; If the next data word contains 0 for the note byte,
                        ; the player returns to the beginning, DATA, and starts over.
                        
PTR    = $04            ; The current song position. It's initialized to DATA
COUNT  = $03            ; Remaining jiffies before the next note

IRQ    = $EABF          ; The IRQ routine. EABF is the hardware default, but if you
                        ; have other things that need to be done, this can be
                        ; set to something else.
                        
VOICE  = $900B          ; This is the voice that's being played by this routine.
                        ;     $900A is the lowest
                        ;     $900B is the middle
                        ;     $900C is the highest
                        ;     $900D is noise

; Sets the IRQ vector. You may or may not want to run this, depending on how
; you use this routine.
START:  PHP
        SEI
        LDA #<PLAY      ; Set the interrupt code
        STA $0314
        LDA #>PLAY
        STA $0315
        JSR RESET
        PLP
        RTS

PLAY:   LDX COUNT
        BEQ NEXT        ; When the count is 0, get and play the next note
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

RESET:  LDA #<DATA      ; Reset the data counter to the beginning of the song
        STA PTR
        LDA #>DATA
        STA PTR + 1
        LDA #$00        ; Reset the duration counter
        STA COUNT
        RTS