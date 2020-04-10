; Sidewinder Maze Generator for Commodore VIC-20
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
; This code generates a maze using the Sidewinder algorithm. Here's a usage
; example:
;
; MAZE_E LDA #$5D
;        STA $900F       ; Set the screen color so that the maze
;                        ;   shows up. This program does not set
;                        ;   any color data.
;        LDA #$18        ; Placement of the maze
;        JSR MAZE
;        RTS
;

* = $1800
BASRND = $E094          ; Routine for BASIC's RND() function
SCPAGE = $0288          ; Screen location start
RNDNUM = $8C            ; Result storage location for RND()
SCRPAD = $01            ; Scratchpad for a function
C_POS  = $02            ; Screen position (16 bits)
OFFSET = $04            ; Screen offset
REMAIN = $05            ; Remaining cells for the current level

; Generate and display an 8x8 maze with the Sidewinder algorithm
;
; The maze is 8x8, but takes up a 16x16 on the screen
;
; Preparations
;     A is the offset location of the maze
;
MAZE:   STA OFFSET
        JSR DRGRID      ; Draw the blank maze grid
        LDX #$00
        JSR SCR_RS      ; Reset screen pointer to the top
        INC C_POS       ; Move to the next space to
        BCC LEVEL       ;   accommodate the left-hand
        INC C_POS+1     ;   maze border
LEVEL:  TXA
        PHA
        JSR DRLEV       ; Draw the level
        PLA
        TAX
        INX
        CPX #$08
        BNE LEVEL
        RTS
        
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SUBROUTINES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; DRGRID - Draw a 16x16 starting background. Maze walls will be
; removed from this background during the build process.
DRGRID: JSR SCR_RS      ; Reset screen pointer to the top
        LDX #$0E
DROP:   LDY #$10
        LDA #$16
        CLC
        ADC C_POS
        STA C_POS
        BCC WALLS
        INC C_POS+1
WALLS:  LDA #$66        ; Maze background character
L_WALL: STA (C_POS),Y
        DEY
        BPL L_WALL
ENDROW: DEX
        BPL DROP
        RTS
        
; DRLEV - Generate and draw a level of the sidewinder maze
;
; Preparations
;     X is the level number
DRLEV:  CPX #$00
        BEQ F_COR
        LDA #$2C        ; Drop to the next level by adding
        CLC             ; 44 (2 lines) to the screen position
        ADC C_POS
        STA C_POS
        BCC F_COR
        INC C_POS+1
F_COR:  LDA #$08        ; Initialize the current level
        TAY             ; Default level length
NX_COR: STA REMAIN      ; Start a new corridor
        CPX #$00        ; Level 0 has a special case; it always
        BEQ DRAW        ;   has a single full-length corridor
        JSR RAND        ; Y = Length of the next corridor
DRAW:   JSR DRCORR      ; Draw the corridor
        STY SCRPAD      ; Update remaining cells by
        LDA REMAIN      ;   subtracting the size of the
        SEC             ;   current corridor from the
        SBC SCRPAD      ;   number of remaining cells
        BNE NX_COR      ; If any cells are left, keep going
        RTS

; DRCORR - Draw a corridor. The starting cell of the corridor
; is be 8 minus the number of remaining cells.
;
; Preparations
;     X is the level number
;     Y is the length of the corridor
DRCORR: LDA C_POS       ; Save the screen position
        PHA
        LDA C_POS+1
        PHA
        TYA             ; Save the Y register for the caller
        PHA
        LDA #$08        ; Find the starting x-axis of this
        SEC             ;   corridor, which is 8 minus the
        SBC REMAIN      ;   number of remaining cells, and
        ASL             ;   multiplying by 2. Then advance
        CLC             ;   the screen position pointer to
        ADC C_POS       ;   the starting location.
        STA C_POS
        BCC KNOCK
        INC C_POS+1
KNOCK:  DEY             ; Keep one wall intact
        TYA             ; Double the length. This is how many
        ASL             ; walls are going to be knocked out.
        TAY
        LDA #$20        ; Knock out walls with a space
KNLOOP: STA (C_POS),Y   ; Knock out Y walls
        DEY
        BPL KNLOOP
; Select a random cell from the corridor and knock out a wall
; directly above it. This provides access to every other open
; cell in the maze.
        CPX #$00        ; If this is the first level, there's
        BEQ RESET       ; no knocking out the ceiling.
        PLA             ; A is now the passed Y register, the
                        ;   length of the corridor.
        PHA             ; But we still need Y for later
        JSR RAND        ; Y is now a random index within the
                        ;   corridor. 
        DEY               
        TYA
        ASL
        TAY
        LDA #$3D        ; Put a ladder at the chosen position
        STA (C_POS),Y
        LDA C_POS
        SEC
        SBC #$16        ; Go up one line
        STA C_POS
        BCS CKNOCK
        DEC C_POS+1
CKNOCK: LDA #$3D        ; Knock out ceiling with a ladder
        STA (C_POS),Y   ; Knock out the ceiling
RESET:  PLA             ; Start restoring things for return
        TAY
        PLA
        STA C_POS+1
        PLA
        STA C_POS
        RTS   
       
; SCR_RS - Reset the screen position pointer to the top left
; of the maze 
SCR_RS: LDA OFFSET
        STA C_POS
        LDA SCPAGE
        STA C_POS+1
        RTS 

; RAND - Get a random number between 1 and 8. A contains the
; maximum value. The random number will be in Y.
RAND:   STA SCRPAD
        DEC SCRPAD      ; Behind the scenes, look for a number
                        ;   between 0 and A - 1. See the INY
                        ;   below, which compensates
        JSR BASRND
        LDA RNDNUM
        AND #$07
        CMP SCRPAD
        BCC E_RAND      ; Get another random number if this one
        BEQ E_RAND      ; is greater than the maximum
        INC SCRPAD
        LDA SCRPAD
        BNE RAND
E_RAND: TAY
        INY
        RTS
