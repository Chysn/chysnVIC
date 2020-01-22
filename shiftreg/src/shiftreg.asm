; Shift Register for Commodore VIC-20
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

; This code is fully-relocatable. You can put it anywhere and it will work.
* = $1800

BASRND = $E094      ; Routine for BASIC's RND() function
RNDNUM = $8C        ; One of the result storage locations for RND()
REG_L  = $FB        ; \ Storage for the 16-bit shift register
REG_H  = $FC        ; /
L_SRCH = $FD        ; Used for length search
NOTE   = $FE        ; Examine this location after calling NXNOTE to determine
                    ; which note to play. This would be something along the lines
                    ; of POKE 36875, PEEK(254) OR 128, with the extra 128 being
                    ; the gate on bit for the voice.

; INIT initializes the shift register with a random 16-bit value. This is optional;
; you may feel free to use what's already in the register locations, or set your own
; initial value, or use some other method to set REG_L and REG_H.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT:   JSR BASRND  ; Call the BASIC RND() function
        LDA RNDNUM
        STA REG_L   ; Use it to set the low byte of the shift register
        JSR BASRND
        LDA RNDNUM
        STA REG_H   ; And the high byte with another RND() call
        RTS

; NXNOTE stores the current note value in the NOTE location (see above). Then,        
; shift the 16-bit register one bit to the left. Do a probability check
; to determine whether the last bit is moved back to bit 0, or is flipped.
;
; Preparations:
;     (1) Set Y register to the probability value (0-127)
;         Probability of 0 means never change the pattern; 127 means always flip bit 0
;     (2) Set X register to the sequence length (1-16)
;         Determines which bit is carried back to bit 0 of the sequence. This is 1-indexed,
;         so a value of 8 means "carry bit 7", or "8 steps long."
;     (3) JSR NXNOTE
;
; Example usage after call:
;     LDA NOTE
;     ORA #$80 ; To gate the note
;     STA {VIC sound register}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
NXNOTE: LDA REG_H   ; Since the VIC-20's frequency values are 7 bits, use the top
        LSR         ; seven bits of the shift register as the frequency value, to be
        STA NOTE    ; saved in memory for use by the caller upon return.

        TYA
        PHA         ; Put probability (0-127) in Y onto the stack for later use
FINDCB: DEX         ; The caller passes length, but the routine uses (length - 1)
                    ; so that AND can be used to mask off steps 9-16 below
        TXA
        LDX REG_H
        CMP #$08    ; Select the high byte or the low byte for length in X; if
                    ; X is 9-16, use the high byte. Otherwise, use the low byte.
        BCS COUNT
        LDX REG_L
COUNT:  STX L_SRCH  ; This is the byte we'll be searching for the last bit
        AND #$07    ; We're counting from bits 0 to 7 within the L_SRCH byte
        TAX
        INX         ; X will now be the actual length, but within the selected byte
        LDA #$01    ; A will now be set to indicate the last bit of the pattern
ADVANC: DEX
        BEQ FOUND
        ASL
        CLC
        BCC ADVANC
FOUND:  BIT L_SRCH
        BEQ ONE
        LDX #$00    ; The last bit of the pattern is 0
        BEQ ROT_H
ONE:    LDX #$01    ; The last bit of the pattern is 1

ROT_H:  ASL REG_H   ; Shift high byte left
ROT_L   ASL REG_L   ; Shift low byte left
        BCC ROLL
        LDA #$01    ; Set bit 0 of high byte if bit 7 of the low byte was set
        ORA REG_H
        STA REG_H
ROLL:   CPX #$01
        BEQ CHKPR   ; If the last bit of the pattern was set, roll it to bit 0 of the low
        LDA #$01    ; byte using the same method as before, with an OR to set bit 0
        ORA REG_L
        STA REG_L
CHKPR:  JSR BASRND  ; Make the probability check
        PLA         ; Pull probability from the stack
        CMP RNDNUM
        BEQ DONE
        BCC DONE    ; If A > random number, flip the bit. The higher A is,
                    ; the more likely it is that the bit gets flipped.
        LDA #$01    ; When the probability says flip the bit, do that
        EOR REG_L   ; by XORing the register low bit with value 0000 0001
        STA REG_L   ; and saving the register with the flipped bit

DONE:   RTS
 