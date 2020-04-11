; Shift Register IRQ Player for Commodore VIC-20
; (c)2020, Jason Justian
; based on Turing Machine by Tom Whitwell, Music Thing Modular
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

* = $1800
ISR    = $0314          ; ISR vector
SY_ISR = $EABF          ; System ISR   
VOICEH = $900C
VOICEM = $900B
VOICEL = $900A
NOISE  = $900D  
VOLUME = $900E
                  
REG_L  = $033C          ; \ Storage for the shift register
REG_H  = $033D          ; /
TEMPO  = $033E          ; Tempo (lower numbers are faster)
CDOWN  = $033F          ; Tempo countdown
PLAY   = $0340          ; Music is playing

        
IN_ISR: SEI
        LDA #<PLAYER
        STA ISR
        LDA #>PLAYER
        STA ISR+1
        LDA #$08
        STA TEMPO
        STA CDOWN
        LDA #$32
        STA REG_L
        LDA #$23
        STA REG_H
        JSR M_PLAY
        CLI
        RTS

M_PLAY: LDA #$01
        STA PLAY
        RTS
    
M_STOP  LDA #$00
        STA PLAY
        RTS
                    
; NXNOTE - Rotates the 16-bit register one bit to the left
NXNOTE: LDX #$00        ; X is the carry bit for REG_H
        ASL REG_L       ; Shift the low byte, which may set C
        ROL REG_H       ; Rotate the high byte, including C
        BCC ROLL        ; Was the high bit of the high byte set?
        LDX #$01        ; If so, add it back to the beginning
ROLL    TXA
        ORA REG_L
        STA REG_L
        RTS

; PLAYER - The Interrupt Service Routine. Based on the tempo,
; get the next note and play it.
PLAYER: LDA #$01
        BIT PLAY
        BEQ DEFISR
        DEC TEMPO
        BNE DEFISR
        LDA CDOWN
        STA TEMPO
        JSR NXNOTE
        LDA REG_H
        ORA #$80
        STA VOICEM
        LDA REG_L
        AND #$0F
        STA VOLUME
DEFISR: JMP SY_ISR


