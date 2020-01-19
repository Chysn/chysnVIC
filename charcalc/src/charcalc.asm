; Custom Character Calculator for Commodore VIC-20
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
;
SCPAGE = $0288
SPOS_L = $FB
SPOS_H = $FC
CURBYT = $FD
EMPTY  = $20
DELIM  = $2C

; This code is fully-relocatable. You can put it anywhere in memory and it will work.
* = $1800

; Set a pointer to screen memory, which will be used to scan the screen
INIT:   LDA #$00
        STA SPOS_L
        LDA SCPAGE
        STA SPOS_H
                
; Scan the line from the screen position pointer, 8 characters at a time
SCANLN: LDA #$00
        STA CURBYT
        LDX #$80    ; Set bit 7
        LDY #$00
CHECK:  LDA (SPOS_L),Y
        CMP #EMPTY
        BEQ NEXT
        TXA
        ORA CURBYT
        STA CURBYT
NEXT:   INY
        TXA
        LSR A
        TAX
        BNE CHECK
            
OUTPUT: LDX CURBYT
        JSR $DDCD
            
        ; Are we on the eighth byte of output?
        LDA SPOS_L
        CMP #$9A ; 22 columns x 7
        BEQ EXIT
            
        ; Print a comma, because there's at least one more byte
        LDA #DELIM
        JSR $FFD2
            
        ; Increment the screen pointer by 22 and start scanning the next line down
        CLC
        LDA #$16
        ADC SPOS_L
        STA SPOS_L
        BCC SCANLN
            
EXIT:   RTS
   
