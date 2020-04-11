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
TEMPO  = $033E          ; Tempo counter

        
IN_ISR: SEI
        LDA #<PLAYER
        STA ISR
        LDA #>PLAYER
        STA ISR+1
        LDA #$08
        STA TEMPO
        CLI
        RTS
                    
PLAYER: DEC TEMPO
        BNE DEFISR
        LDA #$08
        STA TEMPO
        JSR NXNOTE
        ORA #$80
        STA VOICEM
        LDA REG_L
        AND #$0F
        STA VOLUME
DEFISR: JMP SY_ISR

; NXNOTE stores the current note value in the NOTE location. 
; Then, shift the 16-bit register one bit to the left, and
; EOR the last bit, and return the result to the beginning of
; the register, to make a 32-step pattern.
NXNOTE: LDA REG_H       ; Since the VIC-20's frequency values
        ASR             ;   are 7 bits, use the top seven bits
        PHA             ;   of the seven bits of the shift 
                        ;   register as the frequency value
        LDX #$00        ; X is the carry bit for REG_H
        CLC
        ASL REG_L
        ROL REG_H
        BCC ROLL
        LDX #$01
ROLL    TXA
        ORA REG_L
        STA REG_L
        PLA
        RTS

