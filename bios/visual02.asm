; *******************************************************************
; *** This software is copyright 2020 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

;[RLA] These are defined on the rcasm command line!
;[RLA] #define ELFOS            ; build the version that runs under Elf/OS
;[RLA] #define STGROM           ; build the STG EPROM version
;[RLA] #define PICOROM          ; define for Mike's PIcoElf version

;[RLA]   rcasm doesn't have any way to do a logical "OR" of assembly
;[RLA] options, so define a master "ANYROM" option that's true for
;[RLA] any of the ROM conditions...

#ifdef PICOROM
#define ANYROM
#endif

#ifdef STGROM
#define ANYROM
#endif

#ifdef STGROM
;[RLA] STG ROM addresses and options
include config.inc
#endif

include    bios.inc
#ifdef ELFOS
include    kernel.inc
#endif

; R7 - pointer to R[]
; R8.0 - D
; R8.1 - DF
; R9.0 - P
; R9.1 - X
; RF - temporary use
; RA - Set R7 routine
; RB - Retrieve R[r7] into rf

#ifdef PICOROM
           org     0e000h
edtasm:    equ     0b000h
#else
#ifdef STGROM
           org     VISUAL
;[RLA]  So, for the STGROM we don't actually need to define edtasm.  That's
;[RLA] because the config.inc file defines EDTASM, and the current rcasm
;[RLA] implementation is case INSENSITIVE for macro substitutions.  The code
;[RLA] down below at asm: will just naturally do the right thing without any
;[RLA] additional help.  If Mike ever changes rcasm to make #defines case
;[RLA] sensitive, then you'll need this line.
;[RLA]edtasm:      equ     EDTASM

#else
#ifdef ELFOS
           org     0e000h
#else
           org     8000h
#endif
#endif
#endif


start:     lbr     start2            ; jump past warm start
           lbr     begin             ; do not need initcall
start2:    ldi     r0.1              ; get data segment
           phi     r2                ; set into stack register
           ldi     0ffh              ; stack will be at end of segment
           plo     r2
           sex     r2                ; set x to 2
           ldi     high begin
           phi     r6
           ldi     low begin
           plo     r6
           lbr     f_initcall


incr:      sep     ra                ; set R7 to correct register
incr2:     sep     rb                ; retrieve R register value into rf
           inc     rf                ; increment value
           inc     r7
           glo     rf                ; write value back to R register
           str     r7
           dec     r7
           ghi     rf
           str     r7
           sep     sret

           db      0,'ADC ',0
doadc:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           adc                       ; perform add
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     instdn

           db      2,'ADCI',0
doadci:    glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           adc                       ; perform add
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     incp

           db      0,'ADD ',0
doadd:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           add                       ; perform add
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     instdn

           db      2,'ADI ',0
doadi:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           add                       ; perform add
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     incp              ; then increment p

           db      0,'AND ',0
doand:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           and                       ; perform and
           plo     r8                ; put back into D
           sex     r2                ; restore x
           lbr     instdn

           db      2,'ANI ',0
doani:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           and                       ; perform and
           plo     r8                ; put back into D
           sex     r2                ; restore x
           lbr     incp

           db      2,'B1  ',0
dob1:      b1      dob1_yes
           lbr     incp              ; otherwise increment R[P]
dob1_yes:  lbr     dobr              ; branch

           db      2,'B2  ',0
dob2:      b2      dob1_yes          ; branch if b1 set
           lbr     incp              ; otherwise increment R[P]

           db      2,'B3  ',0
dob3:      b3      dob1_yes          ; branch if b1 set
           lbr     incp              ; otherwise increment R[P]

           db      2,'B4  ',0
dob4:      b4      dob1_yes          ; branch if b1 set
           lbr     incp              ; otherwise increment R[P]

           db      2,'BN1 ',0
dobn1:     bn1     dob1_yes 
           lbr     incp              ; otherwise increment

           db      2,'BN2 ',0
dobn2:     bn2     dob1_yes 
           lbr     incp              ; otherwise increment

           db      2,'BN3 ',0
dobn3:     bn3     dob1_yes 
           lbr     incp              ; otherwise increment

           db      2,'BN4 ',0
dobn4:     bn4     dob1_yes 
           lbr     incp              ; otherwise increment

           db      1,'NBR ',0
donbr:     lbr     incp 

           db      2,'BDF ',0
dobdf:     ghi     r8                ; get DF
           shr                       ; shift into df
           lbdf    dobr              ; branch if df is set
           lbr     incp              ; otherwise increment R[P]

           db      2,'BNF ',0
dobnf:     ghi     r8                ; get DF
           shr                       ; shift into df
           lbnf    dobr              ; branch if df not set
           lbr     incp              ; otherwise increment R[P]

           db      2,'BNQ ',0
dobnq:     ldi     q.0               ; address of Q
           plo     r7                ; set register pointer
           ldn     r7                ; retrieve Q
           lbz     dobr              ; branch if zero
           lbr     incp              ; otherwise increment R[P]

           db      2,'BNZ ',0
dobnz:     glo     r8                ; get D
           lbnz    dobr              ; jump if D<>0
           lbr     incp              ; otherwise increment R[P]

           db      2,'BQ  ',0
dobq:      ldi     q.0               ; address of Q
           plo     r7                ; set register pointer
           ldn     r7                ; retrieve Q
           lbnz    dobr              ; branch if nonzero
           lbr     incp              ; otherwise increment R[P]

           db      2,'BR  ',0
dobr:      glo     r9                ; get P
           sep     ra                ; point r7 to R[P]
           lda     r7                ; retrieve R[P]
           phi     rf
           ldn     r7                ; low byte
           plo     rf
           ldn     rf                ; get branch address
           str     r7                ; write to R[P]
           lbr     instdn

           db      2,'BZ  ',0
dobz:      glo     r8                ; get D
           lbz     dobr              ; jump if D=0
           lbr     incp              ; otherwise increment R[P]

           db      1,'DEC ',0
dodec:     sep     ra                ; set R7 to correct register
           sep     rb                ; retrieve into rf
           dec     rf                ; decrement value
           inc     r7
           glo     rf                ; write value back to R register
           str     r7
           dec     r7
           ghi     rf
           str     r7
           lbr     instdn

           db      0,'DIS ',0
dodis:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           ghi     r9                ; need to keep original X
           plo     re
           ldn     rf                ; get value from memory
           ani     0fh               ; keep only low nybble
           plo     r9                ; put into P
           ldn     rf                ; get value from memory again
           shr                       ; shift high nybble to low
           shr
           shr
           shr
           phi     r9                ; and store into X
           ldi     ie.0              ; address of ie register
           plo     r7
           ldi     0                 ; need to disable
           str     r7
           glo     re                ; recover original X
           lbr     doinc             ; then increment x

           db      0,'IDL ',0
doidl:     lbr     instdn

           db      1,'INC ',0
doinc:     sep     scall             ; Call increment R
           dw      incr
           lbr     instdn

           db      0,'INP1',0
doinp1:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           inp     1                 ; perform out
           sex     r2                ; restore x
           plo     r8                ; store D
           lbr     instdn            ; done

           db      0,'INP2',0
doinp2:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           inp     2                 ; perform out
           sex     r2                ; restore x
           plo     r8                ; store D
           lbr     instdn            ; done

           db      0,'INP3',0
doinp3:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           inp     3                 ; perform out
           sex     r2                ; restore x
           plo     r8                ; store D
           lbr     instdn            ; done

           db      0,'INP4',0
doinp4:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           inp     4                 ; perform out
           sex     r2                ; restore x
           plo     r8                ; store D
           lbr     instdn            ; done

           db      0,'INP5',0
doinp5:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           inp     1                 ; perform out
           sex     r2                ; restore x
           plo     r8                ; store D
           lbr     instdn            ; done

           db      0,'INP6',0
doinp6:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           inp     6                 ; perform out
           sex     r2                ; restore x
           plo     r8                ; store D
           lbr     instdn            ; done

           db      0,'INP7',0
doinp7:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           inp     7                 ; perform out
           sex     r2                ; restore x
           plo     r8                ; store D
           lbr     instdn            ; done

           db      0,'IRX ',0
doirx:     ghi     r9                ; get x
           sep     scall             ; call increment register
           dw      incr
           lbr     instdn            ; finished

           db      1,'GHI ',0
doghi:     sep     ra                ; set R7 to correct R register
           ldn     r7                ; retrieve msb
           plo     r8                ; put into D
           lbr     instdn

           db      1,'GLO ',0
doglo:     sep     ra                ; set R7 to correct R register
           inc     r7                ; point to lsb
           ldn     r7                ; retrieve it
           plo     r8                ; put into D
           lbr     instdn

           db      4,'LBDF',0
dolbdf:    ghi     r8                ; get DF
           shr                       ; shift into df
           lbdf    dolbr             ; perform branch if DF is set
           lbr     donlbr            ; otherwise skip

           db      4,'LBNF',0
dolbnf:    ghi     r8                ; get DF
           shr                       ; shift into df
           lbnf    dolbr             ; perform branch if DF is zero
           lbr     donlbr            ; otherwise skip

           db      4,'LBNQ',0
dolbnq:    ldi     q.0               ; point to Q 
           plo     r7                ; store into register pointer
           ldn     r7                ; get Q
           lbnq    dolbr             ; perform branch if Q is zero
           lbr     donlbr            ; otherwise skip

           db      4,'LBNZ',0
dolbnz:    glo     r8                ; get D
           lbnz    dolbr             ; perform branch if Z is nonzero
           lbr     donlbr            ; otherwise skip

           db      4,'LBQ ',0
dolbq:     ldi     q.0               ; point to Q 
           plo     r7                ; store into register pointer
           ldn     r7                ; get Q
           lbq     dolbr             ; perform branch if Q is set
           lbr     donlbr            ; otherwise skip

           db      4,'LBZ ',0
dolbz:     glo     r8                ; get D
           lbz     dolbr             ; perform branch if Z is zero
           lbr     donlbr            ; otherwise skip

           db      4,'LBR ',0
dolbr:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve into rf
           ldn     rf                ; read high byte
           str     r7                ; store into R[P]
           inc     rf                ; point to low byte
           inc     r7
           ldn     rf                ; read low byte
           str     r7                ; store into R[P]
           lbr     instdn
        
           db      1,'LDA ',0
dolda:     sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve into rf
           ldn     rf
           plo     r8
           sep     scall             ; now increment R
           dw      incr2
           lbr     instdn

           db      2,'LDI ',0
doldi:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           ldn     rf                ; retrieve value from memory
           plo     r8                ; store into D
           lbr     incp              ; increment P

           db      1,'LDN ',0
doldn:     sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve into rf
           ldn     rf
           plo     r8
           lbr     instdn

           db      0,'LDX ',0
doldx:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           ldn     rf                ; retrieve value from memory
           plo     r8                ; store into D
           lbr     instdn

           db      0,'LDXA',0
doldxa:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           ldn     rf                ; retrieve value from memory
           plo     r8                ; store into D
           lbr     doirx             ; then increment R[X]

           db      0,'LSDF',0
dolsdf:    ghi     r8                ; get DF
           shr                       ; shift into df
           lbdf    donlbr            ; perform skip if DF is nonzero
           lbr     instdn            ; otherwise done

           db      0,'LSIE',0
dolsie:    ldi     ie.0              ; point to IE 
           plo     r7                ; store into register pointer
           ldn     r7                ; get Q
           lbnz    donlbr            ; perform skip if IE is nonzero
           lbr     instdn            ; otherwise done

           db      0,'LSNF',0
dolsnf:    ghi     r8                ; get DF
           shr                       ; shift into df
           lbnf    donlbr            ; perform skip if DF is zero
           lbr     instdn            ; otherwise done

           db      0,'LSNQ',0
dolsnq:    ldi     q.0               ; point to Q 
           plo     r7                ; store into register pointer
           ldn     r7                ; get Q
           lbz     donlbr            ; perform skip if Q is zero
           lbr     instdn            ; otherwise done

           db      0,'LSNZ',0
dolsnz:    glo     r8                ; get D
           lbnz    donlbr            ; perform skip if Q is zero
           lbr     instdn            ; otherwise done

           db      0,'LSQ ',0
dolsq:     ldi     q.0               ; point to Q 
           plo     r7                ; store into register pointer
           ldn     r7                ; get Q
           lbnz    donlbr            ; perform skip if Q is nonzero
           lbr     instdn            ; otherwise done

           db      0,'LSZ ',0
dolsz:     glo     r8                ; get D
           lbz     donlbr            ; perform skip if D is zero
           lbr     instdn            ; otherwise done




           db      0,'MARK',0
domark:    ldi     t.0               ; Point to T register
           plo     r7                ; put into register pointer
           glo     r9                ; get P
           str     r7                ; put into T
           ghi     r9                ; get X
           shl                       ; move over 1 nybble
           shl
           shl
           shl
           sex     r7                ; point x to T
           or                        ; combine with P
           str     r7                ; and store it
           sex     r2                ; point x back
           ldi     2                 ; need register 2
           sep     ra                ; set r7
           sep     rb                ; read into rf
           ldi     t.0               ; point to T
           plo     r7                ; set into register pointer
           ldn     r7                ; read t
           str     rf                ; and write to M(R[2])
           glo     r9                ; get P
           phi     r9                ; and copy to X
           dec     rf                ; R[2] - 1
           ldi     2                 ; need to point to R2
           sep     ra                ; set r7 to register
           ghi     rf                ; write value of R[2] back
           str     r7
           inc     r7
           glo     rf
           str     r7
           lbr     instdn

           db      2,'NLBR',0
donlbr:    glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve into rf
           inc     rf                ; add 2
           inc     rf
           ghi     rf                ; write back to R[P]
           str     r7
           inc     r7
           glo     rf                ; get low byte
           str     r7                ; write to R[P]
           lbr     instdn

           db      0,'NOP ',0
donop:     lbr     instdn

           db      0,'OR  ',0
door:      ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           or                        ; perform or
           plo     r8                ; put back into D
           sex     r2                ; restore x
           lbr     instdn

           db      2,'ORI ',0
doori:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           or                        ; perform or
           plo     r8                ; put back into D
           sex     r2                ; restore x
           lbr     incp              ; then increment P

           db      0,'OUT1',0
doout1:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           out     1                 ; perform out
           sex     r2                ; restore x
           lbr     doirx             ; then increment R[X]

           db      0,'OUT2',0
doout2:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           out     2                 ; perform out
           sex     r2                ; restore x
           lbr     doirx             ; then increment R[X]

           db      0,'OUT3',0
doout3:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           out     3                 ; perform out
           sex     r2                ; restore x
           lbr     doirx             ; then increment R[X]

           db      0,'OUT4',0
doout4:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           out     4                 ; perform out
           sex     r2                ; restore x
           lbr     doirx             ; then increment R[X]

           db      0,'OUT5',0
doout5:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           out     5                 ; perform out
           sex     r2                ; restore x
           lbr     doirx             ; then increment R[X]

           db      0,'OUT6',0
doout6:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           out     6                 ; perform out
           sex     r2                ; restore x
           lbr     doirx             ; then increment R[X]

           db      0,'OUT7',0
doout7:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           out     7                 ; perform out
           sex     r2                ; restore x
           lbr     doirx             ; then increment R[X]

           db      1,'PHI ',0
dophi:     sep     ra                ; set R7 to correct R register
           glo     r8                ; get D
           str     r7                ; store into R register
           lbr     instdn

           db      1,'PLO ',0
doplo:     sep     ra                ; set R7 to correct R register
           inc     r7                ; point to lsb
           glo     r8                ; get D
           str     r7                ; store into R register
           lbr     instdn

           db      0,'RET ',0
doret:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           ghi     r9                ; save current X
           plo     re
           ldn     rf                ; get value from memory
           ani     0fh               ; keep only low nybble
           plo     r9                ; put into P
           ldn     rf                ; get value from memory again
           shr                       ; shift high nybble to low
           shr
           shr
           shr
           phi     r9                ; and store into X
           ldi     ie.0              ; address of ie register
           plo     r7
           ldi     1                 ; need to enable
           str     r7
           glo     re                ; recover original X
           lbr     doinc             ; then increment x

           db      0,'REQ ',0
doreq:     ldi     q.0               ; need address of Q
           plo     r7                ; set into register pointer
           ldi     0                 ; need zero
           str     r7                ; save to Q
           lbr     instdn

           db      0,'SAV ',0
dosav:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           ldi     t.0               ; point to T register
           plo     r7                ; put into register pointer
           ldn     r7                ; read value of T
           str     rf                ; store to M(R[X])
           lbr     instdn

           db      0,'SD  ',0
dosd:      ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           sd                        ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     instdn

           db      0,'SDB ',0
dosdb:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           sdb                       ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     instdn

           db      2,'SDBI',0
dosdbi:    glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           sdb                       ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     incp

           db      2,'SDI ',0
dosdi:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           sd                        ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     incp              ; then increment p

           db      1,'SEP ',0
dosep:     plo     r9                ; store into P
           lbr     instdn

           db      0,'SEQ ',0
doseq:     ldi     q.0               ; need address of Q
           plo     r7                ; set into register pointer
           ldi     1                 ; need one
           str     r7                ; save to Q
           lbr     instdn

           db      1,'SEX ',0
dosex:     phi     r9                ; store into X
           lbr     instdn

           db      0,'SHL ',0
doshl:     glo     r8                ; get D
           shl                       ; shift left
           plo     r8                ; put it back
           shlc                      ; shift df into d
           phi     r8                ; store into DF
           lbr     instdn

           db      0,'SHLC',0
doshlc:    ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           shlc                      ; shift right
           plo     r8                ; put it back
           shlc                      ; shift df into d
           phi     r8                ; store into DF
           lbr     instdn

           db      0,'SHR ',0
doshr:     glo     r8                ; get D
           shr                       ; shift right
           plo     r8                ; put it back
           shlc                      ; shift df into d
           phi     r8                ; store into DF
           lbr     instdn

           db      0,'SHRC',0
doshrc:    ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           shrc                      ; shift right
           plo     r8                ; put it back
           shlc                      ; shift df into d
           phi     r8                ; store into DF
           lbr     instdn

           db      0,'SM  ',0
dosm:      ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           sm                        ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     instdn

           db      0,'SMB ',0
dosmb:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           smb                       ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     instdn

           db      2,'SMBI',0
dosmbi:    glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           ghi     r8                ; get DF
           shr                       ; shift bit into df
           glo     r8                ; get D
           smb                       ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     incp

           db      2,'SMI ',0
dosmi:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           sm                        ; perform subtraction
           plo     r8                ; put back into D
           shlc                      ; get DF
           phi     r8                ; store DF
           sex     r2                ; restore x
           lbr     incp              ; then increment p

           db      1,'STR ',0
dostr:     sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve into rf
           glo     r8                ; get D
           str     rf                ; store into memory
           lbr     instdn

           db      0,'STXD',0
dostxd:    ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve into rf
           glo     r8                ; get D
           str     rf                ; store into memory
           ghi     r9                ; get X
           lbr     dodec             ; then decrement R[X]

           db      0,'XOR ',0
doxor:     ghi     r9                ; get X
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           xor                       ; perform xor
           plo     r8                ; put back into D
           sex     r2                ; restore x
           lbr     instdn

           db      2,'XRI ',0
doxri:     glo     r9                ; get P
           sep     ra                ; set R7 to correct R register
           sep     rb                ; retrieve value into rf
           sex     rf                ; point x to RF
           glo     r8                ; get D
           xor                       ; perform xor
           plo     r8                ; put back into D
           sex     r2                ; restore x
           lbr     incp              ; and increment P

setr7ret:  sep     r3                ; Return to caller
setr7:     shl                       ; each R register is two bytes
           plo     r7                ; put into R register pointer
           lbr     setr7ret          ; and return to caller
           
retrr7ret: sep     r3                ; Return to caller
retrr7:    lda     r7                ; get high value
           phi     rf
           ldn     r7
           plo     rf
           dec     r7
           lbr     retrr7ret

incp:      glo     r9                ; get p
           sep     scall             ; increment it
           dw      incr
           lbr     instdn            ; jump to instruction done

; ******************************************
; ***** Done with instruction handlers *****
; ******************************************
           
; *********************************************************
; ***** Takes value in D and makes 2 char ascii in RF *****
; *********************************************************
itoa:      plo     rf                ; save value
           ldi     0                 ; clear high byte
           phi     rf
           glo     rf                ; recover low
itoalp:    smi     10                ; see if greater than 10
           lbnf    itoadn            ; jump if not
           plo     rf                ; store new value
           ghi     rf                ; get high character
           adi     1                 ; add 1
           phi     rf                ; and put it back
           glo     rf                ; retrieve low character
           lbr     itoalp            ; and keep processing
itoadn:    glo     rf                ; get low character
           adi     030h              ; convert to ascii
           plo     rf                ; put it back
           ghi     rf                ; get high character
           adi     030h              ; convert to ascii
           phi     rf                ; put it back
           sep     sret              ; return to caller

; *********************************************
; ***** Send vt100 sequence to set cursor *****
; ***** RD.0 = y                          *****
; ***** RD.1 = x                          *****
; *********************************************
gotoxy:    ldi     27                ; escape character
           sep     scall             ; write it
           dw      f_type
           ldi     '['               ; square bracket
           sep     scall             ; write it
           dw      f_type
           glo     rd                ; get x
           sep     scall             ; convert to ascii
           dw      itoa
           ghi     rf                ; high character
           sep     scall             ; write it
           dw      f_type
           glo     rf                ; low character
           sep     scall             ; write it
           dw      f_type
           ldi     ';'               ; need separator
           sep     scall             ; write it
           dw      f_type
           ghi     rd                ; get y
           sep     scall             ; convert to ascii
           dw      itoa
           ghi     rf                ; high character
           sep     scall             ; write it
           dw      f_type
           glo     rf                ; low character
           sep     scall             ; write it
           dw      f_type
           ldi     'H'               ; need terminator for position
           sep     scall             ; write it
           dw      f_type
           sep     sret              ; return to caller

invert:    sep     scall             ; send sequence
           dw      f_inmsg
           db      27,'7m',0
           sep     sret              ; return to caller

normal:    sep     scall             ; send sequence
           dw      f_inmsg
           db      27,'27m',0
           sep     sret              ; return to caller

; ***********************************
; ***** Display low nybble in D *****
; ***********************************
disp4:     ani     0fh               ; strip high nybble
           smi     10                ; check for letters
           lbdf    disp42            ; jump if so
           adi     03ah              ; add 10 back and convert to ascii
           sep     scall             ; display it
           dw      f_type
           sep     sret              ; and return
disp42:    adi     'A'               ; convert to ascii letter
           sep     scall             ; display it
           dw      f_type
           sep     sret              ; and return

; ************************************
; ***** Display 8-bit value in D *****
; ************************************
disp8:     stxd                      ; save D
           shr                       ; get high nybble
           shr
           shr
           shr
           sep     scall             ; display it
           dw      disp4
           irx                       ; recover D
           ldx
           sep     scall             ; display low nybble
           dw      disp4
           sep     sret               ; return to caller

; **************************************
; ***** Dispaly 16-bit value in RF *****
; **************************************
disp16:    ghi     rf                ; get high byte
           sep     scall             ; display it
           dw      disp8
           glo     rf                ; get low byte
           sep     scall             ; display it
           dw      disp8
           sep     sret              ; return to caller

; ************************************
; ***** Draw all register values *****
; ************************************
drawregs:  ldi     2                 ; start at first row
           plo     rd                ; put into position
           ldi     7                 ; column
           phi     rd                ; put into position
           ldi     r0.0              ; point to R[0]
           plo     r7                ; put into register pointer
           ldi     0                 ; set count to 0
           plo     rc                ; in rc
regslp:    sep     scall             ; position cursor
           dw      gotoxy
           lda     r7                ; get high byte of next register
           phi     rf                ; put into rf
           lda     r7                ; get low byte of next register
           plo     rf                ; put into rf
           sep     scall             ; display 16 bit value
           dw      disp16
           inc     rd                ; point to next row
           inc     rc                ; increment count
           glo     rc                ; put it back
           ani     0f0h              ; see if done
           lbz     regslp            ; jump if not
           ldi     2                 ; row 2
           plo     rd
           ldi     19                ; column for data
           phi     rd
           sep     scall             ; set position
           dw      gotoxy
           glo     r8                ; get D
           sep     scall             ; and display it
           dw      disp8
           inc     rd                ; point to X box
           inc     rd
           inc     rd
           sep     scall             ; set cursor position
           dw      gotoxy
           ghi     r9                ; get X
           sep     scall             ; display it
           dw      disp4
           inc     rd                ; point to T box
           inc     rd
           inc     rd
           sep     scall             ; set cursor position
           dw      gotoxy
           ldi     t.0               ; need low address
           plo     r7                ; put into register pointer
           ldn     r7                ; retrieve T
           sep     scall             ; and display it
           dw      disp8
           inc     rd                ; point to Q box
           inc     rd
           inc     rd
           sep     scall             ; set cursor position
           dw      gotoxy
           ldi     q.0               ; need low address
           plo     r7                ; put into register pointer
           ldn     r7                ; retrieve Q
           ani     1                 ; keep only low bit
           sep     scall             ; and display it
           dw      disp4
           inc     rd                ; point to IE box
           inc     rd
           inc     rd
           sep     scall             ; set cursor position
           dw      gotoxy
           ldi     ie.0               ; need low address
           plo     r7                ; put into register pointer
           ldn     r7                ; retrieve IE
           ani     1                 ; keep only low bit
           sep     scall             ; and display it
           dw      disp4
           ldi     2                 ; row 2
           plo     rd
           ldi     29                ; column for data
           phi     rd
           sep     scall             ; set position
           dw      gotoxy
           ghi     r8                ; get DF
           ani     1                 ; keep only low bit
           sep     scall             ; and display it
           dw      disp4
           inc     rd                ; point to P box
           inc     rd
           inc     rd
           sep     scall             ; set cursor position
           dw      gotoxy
           glo     r9                ; get P
           sep     scall             ; display it
           dw      disp4

           sep     sret              ; otherwise return

; ************************************
; ***** Draw single register box *****
; ************************************
drawbox:   sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; display message
           dw      f_inmsg
           db      '+-------+',0
           inc     rd                ; next row
           sep     scall             ; set position
           dw      gotoxy
           sep     scall             ; display message
           dw      f_inmsg
           db      '| ',0
           ghi     rc                ; get first passed character
           sep     scall             ; and display it
           dw      f_type
           glo     rc                ; get second passed character
           sep     scall
           dw      f_type
           sep     scall             ; now finish line
           dw      f_inmsg
           db      '    |',0
           inc     rd
           sep     scall             ; set position
           dw      gotoxy
           sep     scall             ; display message
           dw      f_inmsg
           db      '+-------+',0
           inc     rd                ; increment row
           sep     sret              ; return to caller

; *********************************************************
; ***** Draw larger boxes for disassembly/memory dump *****
; *********************************************************
drawbig:   sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; draw top line
           dw      f_inmsg
           db      '+------------------------------+',0
           inc     rd                ; point to next line
           ldi     7                 ; need 7 lines
           plo     rc
biglp:     sep     scall             ; position cursor
           dw      gotoxy
           ldi     '|'               ; frame character
           sep     scall             ; display it
           dw      f_type
           ghi     rd                ; get x coordinate
           adi     31                ; point to right side
           phi     rd                ; put back into coordinates
           sep     scall             ; position cursor
           dw      gotoxy
           ldi     '|'               ; border character
           sep     scall             ; display it
           dw      f_type
           ghi     rd                ; get x coordinate
           smi     31                ; move it back
           phi     rd
           inc     rd                ; point to next line
           dec     rc                ; decrement count 
           glo     rc                ; need to see if done
           lbnz    biglp             ; jump if not
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; draw bottom line
           dw      f_inmsg
           db      '+------------------------------+',0
           sep     sret              ; return to caller

; *****************************
; ***** Draw basic screen *****
; *****************************
drawscn:   ldi     1                 ; start at first row
           phi     rd
           plo     rd
           ldi     16
           plo     rc
           sep     scall             ; position cursor
           dw      gotoxy
           sep     scall             ; draw first part
           dw      f_inmsg
           db      '+----------+',0
           inc     rd                ; point to 2nd row
drawlp1:   sep     scall
           dw      gotoxy
           sep     scall             ; draw row
           dw      f_inmsg
           db      '|          |',0
           inc     rd                ; next row
           dec     rc                ; decrement row count
           glo     rc                ; get count
           lbnz    drawlp1           ; loop back if not done
           sep     scall             ; position cursor for last row
           dw      gotoxy
           sep     scall             ; draw last row
           dw      f_inmsg
           db      '+----------+',0
           ldi     2                 ; start at first row
           plo     rd                ; put into position
           ldi     3                 ; column 3
           phi     rd
           ldi     0                 ; start with 0
           plo     rc                ; store it
drawlp:    sep     scall             ; set cursor position
           dw      gotoxy
           ldi     'R'               ; need R
           sep     scall             ; display it
           dw      f_type
           glo     rc                ; get current count
           sep     scall             ; and display it
           dw      disp4
           inc     rd                ; next row
           glo     rc                ; get count
           adi     1                 ; add 1
           plo     rc                ; put it back
           ani     0f0h              ; did we draw all 16
           lbz     drawlp            ; loop back if not
           ldi     1                 ; row 1
           plo     rd
           ldi     14                ; set column
           phi     rd 
           ldi     'D'               ; draw D register box
           phi     rc
           ldi     ' '
           plo     rc
           sep     scall
           dw      drawbox
           ldi     'X'               ; draw X register box
           phi     rc
           ldi     ' '
           plo     rc
           sep     scall
           dw      drawbox
           ldi     'T'               ; draw T register box
           phi     rc
           ldi     ' '
           plo     rc
           sep     scall
           dw      drawbox
           ldi     'Q'               ; draw Q box
           phi     rc
           ldi     ' '
           plo     rc
           sep     scall
           dw      drawbox
           ldi     'I'               ; draw IE box
           phi     rc
           ldi     'E'
           plo     rc
           sep     scall
           dw      drawbox
           ldi     24                ; setup position for second column
           phi     rd
           ldi     1
           plo     rd
           ldi     'D'               ; draw DF box
           phi     rc
           ldi     'F'
           plo     rc
           sep     scall
           dw      drawbox
           ldi     'P'               ; draw P register box
           phi     rc
           ldi     ' '
           plo     rc
           sep     scall
           dw      drawbox
           inc     rd                ; next row
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; display breakpoint label
           dw      f_inmsg
           db      '   BRK:',0
           ldi     67                ; position for traps label
           phi     rd
           ldi     2
           plo     rd
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; now draw label
           dw      f_inmsg
           db      'TRAPS',0
           ldi     34                ; X address of disassembly box
           phi     rd
           ldi     1                 ; Y address of disassembly box
           plo     rd
           sep     scall             ; draw disassembly box
           dw      drawbig
           inc     rd                ; move down a line
           sep     scall             ; draw memory dump box
           dw      drawbig
           sep     sret              ; otherwise return to caller

begin:     ldi     r0.1              ; Get address of register array
           phi     r7                ; and set R7
           mov     ra,setr7          ; set RA to set r7 routine
           mov     rb,retrr7         ; get RB to R[r7]->rf
           ldi     r0.1              ; get data segment
           phi     r2                ; set into stack register
           ldi     0ffh              ; stack will be at end of segment
           plo     r2
           ldi     nbp.0             ; number of breakpoints
           plo     r7
           ldi     0                 ; set to zero
           str     r7
           ldi     ntraps.0          ; number of traps
           plo     r7
           ldi     0                 ; set to zero
           plo     r7
           ldi     multi.0           ; point to multi execution flag
           plo     r7
           ldi     0                 ; set to zero
           str     r7
           plo     r9                ; set P=0
           phi     r9                ; set X=0


           ldi     0ch               ; clear screen
           sep     scall
           dw      f_type

           sep     scall             ; draw screen
           dw      drawscn
	
	;; added for illegal instruction decode
	   br	   instdn
	   db	   0,'ILL ',0
	
instdn:    ldi     multi.0           ; point to multi execution flags
           plo     r7
           ldn     r7                ; check for multi-execution
           lbz     showregs          ; jump if not
           sep     scall             ; check for break
           dw      checkbp           ; check for break point
           lbdf    showregs          ; jump if breakpoint hit
           sep     scall             ; check for traps
           dw      checktp
           lbdf    showregs          ; jump if trap hit
           ldi     mcount.0          ; get address of instruction count
           plo     r7                ; put into data pointer
           sep     rb                ; retrieve current count
           dec     rf                ; decrement count
           ghi     rf                ; put it back
           str     r7
           inc     r7                ; point to low byte
           glo     rf
           str     r7
           lbnz    cycle             ; jump if more to execute
           ghi     rf                ; get high byte of count
           lbz     showregs          ; jump if done
           lbr     cycle             ; otherwise begin another cycle

checkbp:   glo     r9                ; need P
           sep     ra                ; set r7 to correct register
           sep     rb                ; retrieve register value
           ldi     nbp.0             ; need number of breakpoints
           plo     r7 
           ldn     r7                ; retrieve breakpoint count
           lbz     cont              ; continue if there are no breakpoints
           plo     rc                ; save count
           ldi     bp.0              ; point to breakpoint table
           plo     r7                ; r7 now points to breakpoints
checkbp1:  ghi     rf                ; get high of address
           str     r2                ; save it
           lda     r7                ; get high from breakpoint table
           sm                        ; compare to address
           lbnz    checkbp2          ; jump if not the same
           glo     rf                ; get low of address
           str     r2                ; save it
           ldn     r7                ; get low byte from breakpoint table
           sm                        ; and compare
           lbz     stop              ; break point found, so stop
checkbp2:  inc     r7                ; point to next break point
           dec     rc                ; decrement count
           glo     rc                ; get count
           lbnz    checkbp1          ; loop back if more to check
           lbr     cont              ; if not, continue execution

checktp:   glo     r9                ; need P
           sep     ra                ; set r7 to correct register
           sep     rb                ; retrieve register value
           ldn     rf                ; get next instruction
           str     r2                ; save it
           ldi     ntraps.0          ; need number of traps
           plo     r7  
           ldn     r7                ; get number of traps
           lbz     cont              ; continue of no traps defined
           plo     rc                ; place into count
           ldi     traps.0           ; now point to traps
           plo     r7
checktp1:  lda     r7                ; get trap
           sm                        ; check against current instruction
           lbz     stop              ; stop if a match
           dec     rc                ; decrement count
           glo     rc                ; need to see if more to check
           lbnz    checktp1          ; loop back if more
cont:      ldi     0                 ; none found, continue execution
           shr
           sep     sret

stop:      ldi     1
           shr
           sep     sret

showregs:  sep     scall             ; display registers
           dw      drawregs
instdn1:   ldi     21                ; set position for next inst disassembly
           plo     rd
           ldi     1
           phi     rd
           sep     scall             ; set cursor position
           dw      gotoxy
           ldi     '>'               ; marker for next instruction
           sep     scall             ; display it
           dw      f_type
           glo     r9                ; get P
           sep     ra                ; set into r7
           sep     rb                ; retrieve value into rf
           sep     scall             ; disassemble next instruction
           dw      disassem
           dec     rd                ; point to previous line
           sep     scall             ; set cursor position
           dw      gotoxy
           ldi     ' '               ; move over 1 space
           sep     scall             ; display it
           dw      f_type
           ldi     last.0            ; address of last instruction
           plo     r7                ; set into register pointer
           sep     rb                ; retrieve address
           sep     scall             ; disassemble last instruction executed
           dw      disassem

main:      ldi     23                ; position for prompt
           plo     rd
           ldi     1
           phi     rd
           sep     scall             ; set cursor position
           dw      gotoxy

           mov     rf,prompt
           sep     scall             ; display prompt
           dw      f_msg
           ldi     buffer.1          ; point to input buffer
           phi     rf
           ldi     buffer.0
           plo     rf
           sep     scall             ; get input from user
           dw      f_input
           mov     rf,buffer         ; convert to uppercase
           sep     scall
           dw      touc
           ldi     buffer.1          ; point to input buffer
           phi     rf
           ldi     buffer.0
           plo     rf
           ldn     rf                ; get first input byte
           smi     '?'               ; check for dump command
           lbz     dump              ; jump if so
           ldn     rf                ; recover input byte
           smi     '$'               ; check for disassembly command
           lbz     disasm            ; jump if disassembly
           ldn     rf                ; recover input byte
           smi     '!'               ; check for store command
           lbz     store             ; jump if store
           ldn     rf                ; recover input byte
           smi     '@'               ; see if run command
           lbz     run               ; jump if so
           ldn     rf                ; recover input byte
           smi     'P'               ; check for P= command
           lbz     setp              ; jump if so
           ldn     rf                ; recover input byte
           smi     'X'               ; check for X= command
           lbz     setx              ; jump if so
           ldn     rf                ; recover input byte
           smi     'D'               ; check for D= command
           lbz     setd              ; jump if so
           ldn     rf                ; recover input byte
           smi     'Q'               ; check for Q= command
           lbz     setq              ; jump if so
           ldn     rf                ; recover input byte
           smi     'I'               ; check for I command
           lbz     doint             ; jump if so
           ldn     rf                ; recover input byte
           smi     'T'               ; check for T= command
           lbz     sett              ; jump if so
           ldn     rf                ; recover input byte
           smi     'R'               ; check for R= command
           lbz     setr              ; jump if so
           ldn     rf                ; recover input byte
           smi     'B'               ; check for breakpoint commands
           lbz     breakp            ; jump if so
           ldn     rf                ; recover input byte
           smi     'G'               ; check for go command
           lbz     go                ; jump if so
           ldn     rf                ; recover input byte
           smi     'E'               ; check for exit command
           lbz     exit              ; jump if so
#ifdef ANYROM
           ldn     rf                ; recover input byte
           smi     'A'               ; check for assember command
           lbz     asm               ; jump if so
#endif

           ldi     multi.0           ; address of multi-execute flag
           plo     r7                ; put into data pointer
           ldi     0                 ; need to clear it
           str     r7

cycle:     glo     r9                ; get P
           sep     ra                ; Set register pointer
           sep     rb                ; read register into rf
           glo     r7                ; save pointer to R[P]
           plo     re
           ldi     last.0            ; location for last address
           plo     r7                ; set register pointer
           ghi     rf                ; get high byte of address
           str     r7                ; and save it
           inc     r7                ; point to low byte
           glo     rf                ; low byte of address
           str     r7                ; save it
           glo     re                ; recover R[P] address
           plo     r7
           lda     rf                ; get program byte
           plo     re                ; save it for now
           ghi     rf                ; write new value of R[P]
           str     r7
           inc     r7
           glo     rf
           str     r7
           glo     re                ; get instruction
           shl                       ; multiply by 2
           plo     rf                ; put here for now
           ldi     0                 ; need zero
           shlc                      ; shift in carry bit
           phi     rf                ; rd now had instruction offset
           glo     rf                ; get lsb
           str     r2                ; save it
           ldi     inst.0            ; low byte of instruction table
           add                       ; add instruction offset lsb
           plo     rf                ; move to rf
           ghi     rf                ; get high byte
           str     r2                ; store it for add
           ldi     inst.1            ; high byte of instruction gtable
           adc                       ; add msb of instruction offset
           phi     rf                ; rf now points to instruction address
           lda     rf                ; get high byte of address
           phi     r6                ; put into r6 for sret
           ldn     rf                ; get low byte of address
           plo     r6                ; put into r6 for sret
           dec     r2                ; subtract 2 from x for sret
           dec     r2
           glo     re                ; recover instruction byte
           ani     0fh               ; keep only low nybble
           sep     sret              ; return into instruction handler

; **********************
; ***** Go command *****
; **********************
go:        ldi     multi.0           ; need multi-execution flag
           plo     r7
           ldi     1                 ; need to turn it on
           str     r7
           ldi     0                 ; clear count
           inc     r7                ; point to instruction count
           str     r7                ; and store it
           inc     r7                ; point to low byte
           str     r7
           lbr     cycle             ; now start cycling

; ************************
; ***** Exit command *****
; ************************
exit:      ldi     0ch               ; clear screen
           sep     scall
           dw      f_type
#ifdef ANYROM
           lbr     08003h            ; Pico ROM warm start
#else
#ifdef ELFOS
           lbr     o_wrmboot         ; return to Elf/OS
#else
           mov     r0,0f900h         ; pointer to minimon
           sep     r0                ; exit
#endif
#endif

#ifdef ANYROM
; ***********************
; ***** Asm command *****
; ***********************
asm:       mov     r0,edtasm+3
           sep     r0
#endif

; ******************************************
; ***** Move memory RF->RD, RC.0 count *****
; ******************************************
move:      lda     rf                ; get source byte
           str     rd                ; store into destination
           inc     rd                ; increment destination
           dec     rc                ; decrement count
           glo     rc                ; see if done
           lbnz    move              ; jump if not
           sep     sret              ; return to caller

; ****************************************
; ***** Convert ascii hex to binary  *****
; ***** RF - Pointer to ascii string *****
; ***** Returns: RC - binary value   *****
; ****************************************
tohex:     ldi     0h                ; clear return value
           plo     rc
           phi     rc
tohexlp:   ldn     rf                ; get next byte
           smi     '0'               ; check for bottom of range
           lbnf    tohexdn           ; jump if non-numeric
           ldn     rf                ; recover byte
           smi     '9'+1             ; upper range of digits
           lbnf    tohexd            ; jump if digit
           ldn     rf                ; recover character
           smi     'A'               ; check below uc A
           lbnf    tohexdn           ; jump if not hex character
           ldn     rf                ; recover character
           smi     'F'+1             ; check for uppercase hex
           lbnf    tohexuc           ; jump if so
           ldn     rf                ; recover character
           smi     'a'               ; check below lc A
           lbnf    tohexdn           ; jump if not hex character
           ldn     rf                ; recover character
           smi     'f'+1             ; check for lowercase hex
           lbdf    tohexdn           ; jump if not
tohexlc:   lda     rf                ; recover character
           smi     87                ; convert to binary
           lbr     tohexad           ; and add it in
tohexuc:   lda     rf                ; recover character
           smi     55                ; convert to binary
           lbr     tohexad
tohexd:    lda     rf                ; recover character
           smi     030h              ; convert to binary       
tohexad:   str     r2                ; store value to add
           ldi     4                 ; need to shift 4 times
           plo     re
tohexal:   shl     rc
           dec     re                ; decrement count
           glo     re                ; get count
           lbnz    tohexal           ; loop until done
           glo     rc                ; now add in new value
           or                        ; or with stored byte
           plo     rc
           lbr     tohexlp           ; loop back for next character
tohexdn:   sep     sret              ; return to caller


; *****************************************
; ***** Disassemble instruction at rf *****
; *****************************************
disassem:  push    rf                ; save address
           sep     scall             ; display address
           dw      disp16
           ldi     ' '               ; display a space
           sep     scall
           dw      f_type
           ldn     rf                ; get instruction byte
           shl                       ; multiply by 2
           plo     rc                ; put into rc
           ldi     0                 ; need the carry
           shlc 
           phi     rc                ; rc now has instruction offset
           glo     rc                ; get low byte
           adi     inst.0            ; add in instruction table
           plo     rc
           ghi     rc                ; get high byte
           adci    inst.1            ; add
           phi     rc                ; rc now points to instruction offset
           lda     rc                ; get high byte of offset
           phi     rf                ; put into rf
           ldn     rc                ; get low byte
           plo     rf                ; put into rf
           dec     rf                ; move to disassembly record
           dec     rf
           dec     rf
           dec     rf
           dec     rf
           dec     rf
           lda     rf                ; get instruction type
           plo     rc                ; save it
           sep     scall             ; display instruction name
           dw      f_msg
           ldi     ' '               ; following space
           sep     scall             ; display it
           dw      f_type
           pop     rf                ; recover address
           glo     rc                ; get argument type
           lbz     dadone            ; jump if no argument
           smi     1                 ; need to check for type 1
           lbz     da1               ; jump if type 1
           smi     1                 ; need to check for type 2
           lbz     da2               ; jump if type 2
           inc     rf                ; move past instruction byte
           push    rf                ; save address
           lda     rf                ; get high byte of argument
           plo     rc                ; save for a moment
           ldn     rf                ; get low byte
           plo     rf                ; put into rf
           glo     rc                ; get high byte
           phi     rf                ; rf now has 16-bit argument
           sep     scall             ; display it
           dw      disp16
           pop     rf                ; recover address
           inc     rf                ; move past argument
           lbr     dadone            ; done
da1:       ldn     rf                ; get instruction byte
           ani     0fh               ; keep only low nybble
           sep     scall             ; display it
           dw      disp4
           lbr     dadone            ; done
da2:       inc     rf                ; move past instruction byte
           ldn     rf                ; get argument byte
           sep     scall             ; display it
           dw      disp8
dadone:    sep     scall             ; clear any trailing bytes
           dw      f_inmsg
           db      '        ',0
           inc     rf                ; move rf past instruction
           sep     sret              ; return to caller

; *****************************************
; ***** Get address from command line *****
; ***** RF = fist byte of address     *****
; ***** Returns RF: address           *****
; *****************************************
getaddr:   ldn     rf                ; get byte from command line
           smi     'P'               ; check for P
           lbz     getaddrp          ; jump if so
           ldn     rf                ; recover byte
           smi     'X'               ; check for X
           lbz     getaddrx          ; jump if so
           ldn     rf                ; recover byte
           smi     'R'               ; check for R
           lbz     getaddrr          ; jump if so
           sep     scall             ; from from ascii
           dw      tohex
           mov     rf,rc             ; transfer address to rf
           sep     sret              ; returnturn
getaddrp:  glo     r9                ; get P
getaddrgo: sep     ra                ; set r7 to correct register
           sep     rb                ; retrieve value into rf
           sep     sret              ; and return to caller
getaddrx:  ghi     r9                ; get X
           lbr     getaddrgo         ; and then retrieve
getaddrr:  inc     rf                ; point to next character
           sep     scall             ; get number from input
           dw      tohex
           glo     rc                ; get lowest byte
           ani     0fh               ; and only lowest nybble
           lbr     getaddrgo         ; and retrieve value

; ******************************************
; ***** Handle disassemble ($) command *****
; ******************************************
disasm:    inc     rf                ; point to next byte
           sep     scall             ; retrieve address
           dw      getaddr
dodisasm:  ldi     36                ; position of dump box
           phi     rd                ; set position
           ldi     2                 ; row
           plo     rd
           ldi     7                 ; 7 lines to display
           plo     rc
disasmlp:  push    rf                ; save address
           sep     scall             ; position cursor
           dw      gotoxy
           pop     rf                ; recover address
           glo     rc                ; save count
           stxd
           sep     scall             ; disassemble line
           dw      disassem
           irx                       ; recover count
           ldx
           plo     rc
           inc     rd                ; move to next row
           dec     rc                ; decrement line count
           glo     rc                ; get count
           lbnz    disasmlp          ; loop back if not done
           lbr     main



; ***********************************
; ***** Handle dump (?) command *****
; ***********************************
dump:      inc     rf                ; point to next byte
           sep     scall             ; get address
           dw      getaddr
dodump:    ldi     36                ; position of dump box
           phi     rd
           ldi     11
           plo     rd
           ldi     7                 ; seven lines to dump
           phi     rc                ; place into counter
dumplpy:   push    rf                ; save address
           sep     scall             ; position cursor
           dw      gotoxy
           pop     rf                ; recover address
           sep     scall             ; display address
           dw      disp16
           ldi     8                 ; 8 bytes to write
           plo     rc
dumplpx:   ldi     ' '               ; need a space
           sep     scall             ; display it
           dw      f_type
           lda     rf                ; get next byte
           sep     scall             ; display it
           dw      disp8
           dec     rc                ; decrement x count
           glo     rc                ; are we done?
           lbnz    dumplpx           ; loop back if not
           inc     rd                ; move to next row
           ghi     rc                ; get row count
           smi     1                 ; subtract 1
           phi     rc                ; put it back
           lbnz    dumplpy           ; loop back if not done
           lbr     main              ; done, so jump back

; *****************************
; ***** Store (!) command *****
; *****************************
store:     inc     rf                ; point to next byte
           push    rf                ; save buffer postion
           sep     scall             ; get address
           dw      getaddr
           glo     rf                ; transfer address to rd
           plo     rd
           ghi     rf
           phi     rd
           pop     rf                ; recover buffer address
store1:    ldn     rf                ; get character from buffer
           lbz     main              ; jump if end of input
           smi     ' '               ; look for a space
           lbz     storelp           ; jump if found
           inc     rf                ; otherwise move to next character
           lbr     store1            ; and keep looking
storelp:   ldn     rf                ; get next character
           lbz     instdn1           ; jump if end of string
           smi     ' '               ; check for space
           lbnz    store2            ; jump if not
           inc     rf                ; move past space
           lbr     storelp           ; and loop back
store2:    sep     scall             ; retrieve next value
           dw      tohex
           glo     rc                ; get only lowest byte
           str     rd                ; store into destination
           inc     rd                ; increment pointer
           lbr     storelp           ; loop back for next byte
           
; ***************************
; ***** Run (@) command *****
; ***************************
run:       inc     rf                ; move to address
           sep     scall             ; get address
           dw      getaddr
           ldi     r0.0              ; need to set into R[0]
           plo     r7                ; set register pointer
           ghi     rf                ; get high byte of address
           str     r7                ; and store it
           inc     r7                ; point to low byte
           glo     rf                ; get low byte of address
           str     r7                ; and store it
           ldi     0                 ; need to zero
           plo     r9                ; P
           phi     r9                ; and X
           lbr     instdn            ; back to main loop

; *****************************
; **** Set P (P=) command *****
; *****************************
setp:      inc     rf                ; point to next character
           lda     rf                ; retrieve it
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           glo     rc                ; get lowest byte
           ani     0fh               ; lowest nybble
           plo     r9                ; set P
           lbr     showregs          ; then back to main

; *****************************
; **** Set X (X=) command *****
; *****************************
setx:      inc     rf                ; point to next character
           lda     rf                ; retrieve it
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           glo     rc                ; get lowest byte
           ani     0fh               ; lowest nybble
           phi     r9                ; set X
           lbr     showregs          ; then back to main

; ******************************
; ***** Set D (D=) command *****
; ******************************
setd:      inc     rf                ; point to next character
           ldn     rf                ; retrieve next character
           smi     'F'               ; check for DF= command
           lbz     setdf             ; jump if so
           lda     rf                ; retrieve character
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           glo     rc                ; get lowest byte
           plo     r8                ; set D
           lbr     showregs          ; then back to main

; ********************************
; ***** Set DF (DF=) command *****
; ********************************
setdf:     inc     rf                ; point to next character
           lda     rf                ; retrieve it
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           glo     rc                ; get lowest byte
           ani     01h               ; lowest bit
           phi     r8                ; set DF
           lbr     showregs          ; then back to main

; ******************************
; ***** Set Q (Q=) command *****
; ******************************
setq:      inc     rf                ; point to next character
           lda     rf                ; retrieve it
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           ldi     q.0               ; need to point to Q register
           plo     r7                ; put into register pointer
           glo     rc                ; get lowest byte
           ani     01h               ; lowest bit
           str     r7                ; set Q
           lbr     showregs          ; then back to main

; ******************************
; ***** Set T (T=) command *****
; ******************************
sett:      inc     rf                ; point to next character
           ldn     rf                ; get next character
           smi     'C'               ; check for TC command
           lbz     trapc             ; jump if so
           ldn     rf                ; retrieve character
           smi     '+'               ; check for T+
           lbz     trapadd           ; jump if add
           ldn     rf                ; retrieve character
           smi     '-'               ; check for T-
           lbz     trapsub           ; jump if remove
           lda     rf                ; retrieve character
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           ldi     t.0               ; point to T register
           plo     r7                ; put into register index
           glo     rc                ; get lowest byte
           str     r7                ; set T
           lbr     showregs          ; then back to main

; *****************************************
; ***** Trigger interrupt (I) command *****
; *****************************************
doint:     inc     rf                ; point to next character
           ldn     rf                ; retrieve it
           lbz     doint1            ; jump if I command
           smi     'E'               ; Check for IE= command
           lbz     setie             ; jump if so
           lbr     main              ; back to main if not valid command
doint1:    ldi     ie.0              ; need IE register
           plo     r7                ; set register index
           ldn     r7                ; get IE
           lbz     main              ; Back to main if interrupts disabled
           ldi     t.0               ; Point to T register
           plo     r7                ; put into register pointer
           glo     r9                ; get P
           str     r7                ; put into T
           ghi     r9                ; get X
           shl                       ; move over 1 nybble
           shl
           shl
           shl
           sex     r7                ; point x to T
           or                        ; combine with P
           str     r7                ; and store it
           sex     r2                ; put x back to 2
           ldi     2                 ; need to set x=2
           phi     r9                ; set X
           ldi     1                 ; need to set p=1
           plo     r9                ; set P
           ldi     ie.0              ; need to clear IE
           plo     r7                ; set register pointer
           ldi     0
           str     r7                ; set IE
           lbr     showregs          ; then back to main loop


; ********************************
; ***** Set DF (DF=) command *****
; ********************************
setie:     inc     rf                ; point to next character
           lda     rf                ; retrieve it
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           ldi     ie.0              ; Need IE register
           plo     r7                ; set into register index
           glo     rc                ; get lowest byte
           ani     01h               ; lowest bit
           str     r7                ; set IE
           lbr     showregs          ; then back to main

; ******************************
; **** Set R (Rn=) command *****
; ******************************
setr:      inc     rf                ; point to next character
           sep     scall             ; get register number
           dw      tohex
           glo     rc                ; get number
           ani     0fh               ; keep only low nybble
           sep     ra                ; setup register address
           lda     rf                ; retrieve next character
           smi     '='               ; must be =
           lbnz    main              ; loop back to main if not
           sep     scall             ; get value
           dw      tohex
           ghi     rc                ; get high byte of value
           str     r7                ; store into R register
           inc     r7                ; point to low byte
           glo     rc                ; get low byte of value
           str     r7                ; and store to R register
           lbr     showregs          ; then back to main

; ********************************
; ***** Show breakpoint list *****
; ********************************
showbp:    ldi     nbp.0             ; get number of breakpoints
           plo     r7                ; point into data pointer
           ldn     r7                ; get number of breakpoints
           plo     rc                ; place into counter
           sdi     8                 ; find number of empty places
           phi     rc                ; keep count for later
           ldi     bp.0              ; address of breakpoints
           plo     r7                ; place into r7
           ldi     27                ; setup screen position
           phi     rd
           ldi     9
           plo     rd
           glo     rc                ; Are there any breakpoints
           lbnz    showbplp1         ; jump if so
           ghi     rc                ; move blank count
           plo     rc                ; to rc
           lbr     showbplp2         ; now show blank lines
showbplp1: sep     scall             ; set cursor position
           dw      gotoxy
           lda     r7                ; get high byte of next bp
           phi     rf                ; store into rf
           lda     r7                ; get low byte of next bp
           plo     rf                ; and store it
           sep     scall             ; now display it
           dw      disp16
           inc     rd                ; next row
           dec     rc                ; decrement count
           glo     rc                ; get it
           lbnz    showbplp1         ; loop until all shown
           ghi     rc                ; get empty count
           plo     rc                ; place in counter
           lbz     main              ; jump if no blank lines needed
showbplp2: sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; draw 4 spaces
           dw      f_inmsg
           db      '    ',0
           inc     rd                ; increment row
           dec     rc                ; decrement count
           glo     rc                ; get count
           lbnz    showbplp2         ; jump if not done
           lbr     main              ; then return to main

; *******************************
; ***** Breakpoint commands *****
; *******************************
breakp:    inc     rf                ; point to next character
           ldn     rf                ; get character
           smi     'C'               ; check for clear command
           lbz     breakc            ; jump to clear breakpoints
           ldn     rf                ; get character back
           smi     '+'               ; see if add
           lbz     breakadd          ; jump if so
           ldn     rf                ; recover character
           smi     '-'               ; see if remove
           lbnz    main              ; jump if not
           inc     rf                ; move past -
           sep     scall             ; get address
           dw      tohex             ; into rc
           ldi     nbp.0             ; need number of breakpoints
           plo     r7                ; put into data pointer
           ldn     r7                ; get number
           lbz     main              ; jump if no breakpoints
           plo     re                ; save count
           ldi     bp.0              ; point to breakpoint table
           plo     r7                ; setup data pointer
           sex     r7                ; need to use for comparisons
breaksub1: ghi     rc                ; get high byte of address
           sm                        ; see if matches
           inc     r7                ; point to low byte
           lbnz    breaksub2         ; jump if no match
           glo     rc                ; get low byte of address
           sm                        ; see if matches
           lbz     breaksub3         ; jump if address found
breaksub2: inc     r7                ; point to next entry
           dec     re                ; decrement count
           glo     re                ; see if done
           lbnz    breaksub1         ; loop if more to check
           sex     r2                ; point x back to R[2]
           lbz     main              ; otherwise return to caller
breaksub3: sex     r2                ; point x back to R[2]
           dec     r7                ; r7 now has pointer
           ghi     r7                ; r7 becomes destination
           phi     rd
           phi     rf                ; put here too
           glo     r7                ; low byte of destination
           plo     rd
           plo     rf
           inc     rf                ; rf needs to be 1 entry up
           inc     rf
           glo     re                ; get count remaining
           lbz     breaksub4         ; jump if it was last entry, nothing to move
           smi     1                 ; 1 entry less
           shl                       ; 2 bytes per entry
           plo     rc                ; rc now has count
           sep     scall             ; call move memory routine
           dw      move
breaksub4: ldi     nbp.0             ; point to number of breakpoints
           plo     r7                ; put into data pointer
           ldn     r7                ; get count
           smi     1                 ; decrement
           str     r7                ; and put it back
           lbr     showbp            ; show remaining breakpoints
breakadd:  ldi     nbp.0             ; point to number of breakpoints
           plo     r7
           ldn     r7                ; get current number
           ani     0f8h              ; check count
           lbnz    main              ; jump if 8 breakpoints already defined
           ldn     r7                ; recover count
           adi     1                 ; 1 more breakpoint
           str     r7                ; put back into count
           smi     1                 ; back to original to compute offset
           shl                       ; two bytes per breakpoint
           str     r2                ; save for add
           ldi     bp.0              ; get offset for bps
           add                       ; add offset
           plo     r7                ; put into destination register
           inc     rf                ; most past +
           sep     scall             ; now get address
           dw      tohex
           ghi     rc                ; get high byte of address
           str     r7                ; store it
           inc     r7                ; point to low byte
           glo     rc                ; get low byte of address
           str     r7                ; and store it
           lbr     showbp            ; show breakpoints
breakc:    ldi     nbp.0             ; point to number of breakpoints
           plo     r7
           ldi     0                 ; clear them out
           str     r7
           lbr     showbp            ; then show them


; ********************************
; ***** Show breakpoint list *****
; ********************************
showtp:    ldi     ntraps.0          ; get number of traps
           plo     r7                ; point into data pointer
           ldn     r7                ; get number of traps
           plo     rc                ; place into counter
           sdi     16                ; find number of empty places
           phi     rc                ; keep count for later
           ldi     traps.0           ; address of traps
           plo     r7                ; place into r7
           ldi     68                ; setup screen position
           phi     rd
           ldi     3
           plo     rd
           glo     rc                ; Are there any traps
           lbnz    showtplp1         ; jump if so
           ghi     rc                ; move blank count
           plo     rc                ; to rc
           lbr     showtplp2         ; now show blank lines
showtplp1: sep     scall             ; set cursor position
           dw      gotoxy
           lda     r7                ; get trap byte
           sep     scall             ; now display it
           dw      disp8
           inc     rd                ; next row
           dec     rc                ; decrement count
           glo     rc                ; get it
           lbnz    showtplp1         ; loop until all shown
           ghi     rc                ; get empty count
           plo     rc                ; place in counter
           lbz     main              ; jump if no blank lines needed
showtplp2: sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; draw 2 spaces
           dw      f_inmsg
           db      '  ',0
           inc     rd                ; increment row
           dec     rc                ; decrement count
           glo     rc                ; get count
           lbnz    showtplp2         ; jump if not done
           lbr     main              ; then return to main

; ***************************
; ***** Clear all traps *****
; ***************************
trapc:     ldi     ntraps.0          ; need address of trap count
           plo     r7                ; put into data pointer
           ldi     0                 ; need to clear
           str     r7                ; write to trap count
           lbr     showtp            ; show trap list

; ********************
; ***** Add trap *****
; ********************
trapadd:   ldi     ntraps.0          ; point to number of traps
           plo     r7
           ldn     r7                ; get current number
           ani     0f0h              ; check count
           lbnz    main              ; jump if 16 traps already defined
           ldn     r7                ; recover count
           adi     1                 ; 1 more trap
           str     r7                ; put back into count
           smi     1                 ; back to original to compute offset
           str     r2                ; save for add
           ldi     traps.0           ; get offset for bps
           add                       ; add offset
           plo     r7                ; put into destination register
           inc     rf                ; most past +
           sep     scall             ; now get value
           dw      tohex
           glo     rc                ; get value
           str     r7                ; and store it
           lbr     showtp            ; show traps

; ***********************
; ***** Remove trap *****
; ***********************
trapsub:   inc     rf                ; move past -
           sep     scall             ; get value
           dw      tohex             ; into rc
           ldi     ntraps.0          ; need number of traps
           plo     r7                ; put into data pointer
           ldn     r7                ; get number
           lbz     main              ; jump if no traps
           plo     re                ; save count
           ldi     traps.0           ; point to trap table
           plo     r7                ; setup data pointer
           sex     r7                ; need to use for comparisons
trapsub1:  glo     rc                ; get value
           sm                        ; see if matches
           lbz     trapsub3          ; jump if address found
trapsub2:  inc     r7                ; point to next entry
           dec     re                ; decrement count
           glo     re                ; see if done
           lbnz    trapsub1          ; loop if more to check
           sex     r2                ; point x back to R[2]
           lbz     main              ; otherwise return to caller
trapsub3:  sex     r2                ; point x back to R[2]
           ghi     r7                ; r7 becomes destination
           phi     rd
           phi     rf                ; put here too
           glo     r7                ; low byte of destination
           plo     rd
           plo     rf
           inc     rf                ; rf needs to be 1 entry up
           glo     re                ; get count remaining
           lbz     trapsub4          ; jump if it was last entry, nothing to move
           smi     1                 ; 1 entry less
           plo     rc                ; rc now has count
           sep     scall             ; call move memory routine
           dw      move
trapsub4:  ldi     ntraps.0          ; point to number of traps
           plo     r7                ; put into data pointer
           ldn     r7                ; get count
           smi     1                 ; decrement
           str     r7                ; and put it back
           lbr     showtp            ; show remaining traps

; **********************************************************
; ***** Convert string to uppercase, honor quoted text *****
; **********************************************************
touc:      ldn     rf                  ; check for quote
           smi     027h
           lbz     touc_qt             ; jump if quote
           ldn     rf                  ; get byte from string
           lbz     touc_dn             ; jump if done
           smi     'a'                 ; check if below lc
           lbnf    touc_nxt            ; jump if so
           smi     27                  ; check upper rage
           lbdf    touc_nxt            ; jump if above lc
           ldn     rf                  ; otherwise convert character to lc
           smi     32
           str     rf
touc_nxt:  inc     rf                  ; point to next character
           lbr     touc                ; loop to check rest of string
touc_dn:   sep     sret                ; return to caller
touc_qt:   inc     rf                  ; move past quote
touc_qlp:  lda     rf                  ; get next character
           lbz     touc_dn             ; exit if terminator found
           smi     027h                ; check for quote charater
           lbz     touc                ; back to main loop if quote
           lbr     touc_qlp            ; otherwise keep looking

inst:      dw      doidl             ; 00 - IDL
           dw      doldn             ; 01 - LDN R1
           dw      doldn             ; 02 - LDN R2
           dw      doldn             ; 03 - LDN R3
           dw      doldn             ; 04 - LDN R4
           dw      doldn             ; 05 - LDN R5
           dw      doldn             ; 06 - LDN R6
           dw      doldn             ; 07 - LDN R7
           dw      doldn             ; 08 - LDN R8
           dw      doldn             ; 09 - LDN R9
           dw      doldn             ; 0A - LDN RA
           dw      doldn             ; 0B - LDN RB
           dw      doldn             ; 0C - LDN RC
           dw      doldn             ; 0D - LDN RD
           dw      doldn             ; 0E - LDN RE
           dw      doldn             ; 0F - LDN RF
           dw      doinc             ; 10 - INC R0
           dw      doinc             ; 11 - INC R1
           dw      doinc             ; 12 - INC R2
           dw      doinc             ; 13 - INC R3
           dw      doinc             ; 14 - INC R4
           dw      doinc             ; 15 - INC R5
           dw      doinc             ; 16 - INC R6
           dw      doinc             ; 17 - INC R7
           dw      doinc             ; 18 - INC R8
           dw      doinc             ; 19 - INC R9
           dw      doinc             ; 1A - INC RA
           dw      doinc             ; 1B - INC RB
           dw      doinc             ; 1C - INC RC
           dw      doinc             ; 1D - INC RD
           dw      doinc             ; 1E - INC RE
           dw      doinc             ; 1F - INC RF
           dw      dodec             ; 20 - DEC R0
           dw      dodec             ; 21 - DEC R1
           dw      dodec             ; 22 - DEC R2
           dw      dodec             ; 23 - DEC R3
           dw      dodec             ; 24 - DEC R4
           dw      dodec             ; 25 - DEC R5
           dw      dodec             ; 26 - DEC R6
           dw      dodec             ; 27 - DEC R7
           dw      dodec             ; 28 - DEC R8
           dw      dodec             ; 29 - DEC R9
           dw      dodec             ; 2A - DEC RA
           dw      dodec             ; 2B - DEC RB
           dw      dodec             ; 2C - DEC RC
           dw      dodec             ; 2D - DEC RD
           dw      dodec             ; 2E - DEC RE
           dw      dodec             ; 2F - DEC RF
           dw      dobr              ; 30 - BR
           dw      dobq              ; 31 - BQ
           dw      dobz              ; 32 - BZ
           dw      dobdf             ; 33 - BDF
           dw      dob1              ; 34 - B1 
           dw      dob2              ; 35 - B2 
           dw      dob3              ; 36 - B3 
           dw      dob4              ; 37 - B4 
           dw      donbr             ; 38 - NBR
           dw      dobnq             ; 39 - BNQ
           dw      dobnz             ; 3A - BNZ
           dw      dobnf             ; 3B - BNF
           dw      dobn1             ; 3C - BN1
           dw      dobn2             ; 3D - BN2
           dw      dobn3             ; 3E - BN3
           dw      dobn4             ; 3F - BN4
           dw      dolda             ; 40 - LDA R0
           dw      dolda             ; 41 - LDA R1
           dw      dolda             ; 42 - LDA R2
           dw      dolda             ; 43 - LDA R3
           dw      dolda             ; 44 - LDA R4
           dw      dolda             ; 45 - LDA R5
           dw      dolda             ; 46 - LDA R6
           dw      dolda             ; 47 - LDA R7
           dw      dolda             ; 48 - LDA R8
           dw      dolda             ; 49 - LDA R9
           dw      dolda             ; 4A - LDA RA
           dw      dolda             ; 4B - LDA RB
           dw      dolda             ; 4C - LDA RC
           dw      dolda             ; 4D - LDA RD
           dw      dolda             ; 4E - LDA RE
           dw      dolda             ; 4F - LDA RF
           dw      dostr             ; 50 - STR R0
           dw      dostr             ; 51 - STR R1
           dw      dostr             ; 52 - STR R2
           dw      dostr             ; 53 - STR R3
           dw      dostr             ; 54 - STR R4
           dw      dostr             ; 55 - STR R5
           dw      dostr             ; 56 - STR R6
           dw      dostr             ; 57 - STR R7
           dw      dostr             ; 58 - STR R8
           dw      dostr             ; 59 - STR R9
           dw      dostr             ; 5A - STR RA
           dw      dostr             ; 5B - STR RB
           dw      dostr             ; 5C - STR RC
           dw      dostr             ; 5D - STR RD
           dw      dostr             ; 5E - STR RE
           dw      dostr             ; 5F - STR RF
           dw      doirx             ; 60 - IRX
           dw      doout1            ; 61 - OUT 1
           dw      doout2            ; 62 - OUT 2
           dw      doout3            ; 63 - OUT 3
           dw      doout4            ; 64 - OUT 4
           dw      doout5            ; 65 - OUT 5
           dw      doout6            ; 66 - OUT 6
           dw      doout7            ; 67 - OUT 7
           dw      instdn            ; 68 - (illegal on 1802)
           dw      doinp1            ; 69 - INP 1
           dw      doinp2            ; 6A - INP 2
           dw      doinp3            ; 6B - INP 3
           dw      doinp4            ; 6C - INP 4
           dw      doinp5            ; 6D - INP 5
           dw      doinp6            ; 6E - INP 6
           dw      doinp7            ; 6F - INP 7
           dw      doret             ; 70 - RET
           dw      dodis             ; 71 - DIS
           dw      doldxa            ; 72 - LDXA
           dw      dostxd            ; 73 - STXD
           dw      doadc             ; 74 - ADC
           dw      dosdb             ; 75 - SDB
           dw      doshrc            ; 76 - SHRC
           dw      dosmb             ; 77 - SMB
           dw      dosav             ; 78 - SAV
           dw      domark            ; 79 - MARK
           dw      doreq             ; 7A - REQ
           dw      doseq             ; 7B - SEQ
           dw      doadci            ; 7C - ADCI
           dw      dosdbi            ; 7D - SDBI
           dw      doshlc            ; 7E - SHLC
           dw      dosmbi            ; 7F - SMBI
           dw      doglo             ; 80 - GLO R0
           dw      doglo             ; 81 - GLO R1
           dw      doglo             ; 82 - GLO R2
           dw      doglo             ; 83 - GLO R3
           dw      doglo             ; 84 - GLO R4
           dw      doglo             ; 85 - GLO R5
           dw      doglo             ; 86 - GLO R6
           dw      doglo             ; 87 - GLO R7
           dw      doglo             ; 88 - GLO R8
           dw      doglo             ; 89 - GLO R9
           dw      doglo             ; 8A - GLO RA
           dw      doglo             ; 8B - GLO RB
           dw      doglo             ; 8C - GLO RC
           dw      doglo             ; 8D - GLO RD
           dw      doglo             ; 8E - GLO RE
           dw      doglo             ; 8F - GLO RF
           dw      doghi             ; 90 - GHI R0
           dw      doghi             ; 91 - GHI R1
           dw      doghi             ; 92 - GHI R2
           dw      doghi             ; 93 - GHI R3
           dw      doghi             ; 94 - GHI R4
           dw      doghi             ; 95 - GHI R5
           dw      doghi             ; 96 - GHI R6
           dw      doghi             ; 97 - GHI R7
           dw      doghi             ; 98 - GHI R8
           dw      doghi             ; 99 - GHI R9
           dw      doghi             ; 9A - GHI RA
           dw      doghi             ; 9B - GHI RB
           dw      doghi             ; 9C - GHI RC
           dw      doghi             ; 9D - GHI RD
           dw      doghi             ; 9E - GHI RE
           dw      doghi             ; 9F - GHI RF
           dw      doplo             ; A0 - PLO R0
           dw      doplo             ; A1 - PLO R1
           dw      doplo             ; A2 - PLO R2
           dw      doplo             ; A3 - PLO R3
           dw      doplo             ; A4 - PLO R4
           dw      doplo             ; A5 - PLO R5
           dw      doplo             ; A6 - PLO R6
           dw      doplo             ; A7 - PLO R7
           dw      doplo             ; A8 - PLO R8
           dw      doplo             ; A9 - PLO R9
           dw      doplo             ; AA - PLO RA
           dw      doplo             ; AB - PLO RB
           dw      doplo             ; AC - PLO RC
           dw      doplo             ; AD - PLO RD
           dw      doplo             ; AE - PLO RE
           dw      doplo             ; AF - PLO RF
           dw      dophi             ; B0 - PHI R0
           dw      dophi             ; B1 - PHI R1
           dw      dophi             ; B2 - PHI R2
           dw      dophi             ; B3 - PHI R3
           dw      dophi             ; B4 - PHI R4
           dw      dophi             ; B5 - PHI R5
           dw      dophi             ; B6 - PHI R6
           dw      dophi             ; B7 - PHI R7
           dw      dophi             ; B8 - PHI R8
           dw      dophi             ; B9 - PHI R9
           dw      dophi             ; BA - PHI RA
           dw      dophi             ; BB - PHI RB
           dw      dophi             ; BC - PHI RC
           dw      dophi             ; BD - PHI RD
           dw      dophi             ; BE - PHI RE
           dw      dophi             ; BF - PHI RF
           dw      dolbr             ; C0 - LBR
           dw      dolbq             ; C1 - LBQ
           dw      dolbz             ; C2 - LBZ
           dw      dolbdf            ; C3 - LBDF
           dw      donop             ; C4 - NOP
           dw      dolsnq            ; C5 - LSNQ
           dw      dolsnz            ; C6 - LSNZ
           dw      dolsnf            ; C6 - LSNF
           dw      donlbr            ; C8 - NLBR
           dw      dolbnq            ; C9 - LBNQ
           dw      dolbnz            ; CA - LBNZ
           dw      dolbnf            ; CB - LBNF
           dw      dolsie            ; CC - LSIE
           dw      dolsq             ; CD - LSQ
           dw      dolsz             ; CE - LSZ
           dw      dolsdf            ; CF - LSDF
           dw      dosep             ; D0 - SEP R0
           dw      dosep             ; D1 - SEP R1
           dw      dosep             ; D2 - SEP R2
           dw      dosep             ; D3 - SEP R3
           dw      dosep             ; D4 - SEP R4
           dw      dosep             ; D5 - SEP R5
           dw      dosep             ; D6 - SEP R6
           dw      dosep             ; D7 - SEP R7
           dw      dosep             ; D8 - SEP R8
           dw      dosep             ; D9 - SEP R9
           dw      dosep             ; DA - SEP RA
           dw      dosep             ; DB - SEP RB
           dw      dosep             ; DC - SEP RC
           dw      dosep             ; DD - SEP RD
           dw      dosep             ; DE - SEP RE
           dw      dosep             ; DF - SEP RF
           dw      dosex             ; E0 - SEX R0
           dw      dosex             ; E1 - SEX R1
           dw      dosex             ; E2 - SEX R2
           dw      dosex             ; E3 - SEX R3
           dw      dosex             ; E4 - SEX R4
           dw      dosex             ; E5 - SEX R5
           dw      dosex             ; E6 - SEX R6
           dw      dosex             ; E7 - SEX R7
           dw      dosex             ; E8 - SEX R8
           dw      dosex             ; E9 - SEX R9
           dw      dosex             ; EA - SEX RA
           dw      dosex             ; EB - SEX RB
           dw      dosex             ; EC - SEX RC
           dw      dosex             ; ED - SEX RD
           dw      dosex             ; EE - SEX RE
           dw      dosex             ; EF - SEX RF
           dw      doldx             ; F0 - LDX
           dw      door              ; F1 - OR
           dw      doand             ; F2 - AND
           dw      doxor             ; F3 - XOR
           dw      doadd             ; F4 - ADD
           dw      dosd              ; F5 - SD
           dw      doshr             ; F6 - SHR
           dw      dosm              ; F7 - SM
           dw      doldi             ; F8 - LDI
           dw      doori             ; F9 - ORI
           dw      doani             ; FA - ANI
           dw      doxri             ; FB - XRI
           dw      doadi             ; FC - ADI
           dw      dosdi             ; FD - SDI
           dw      doshl             ; FE - SHL
           dw      dosmi             ; FF - SMI
prompt:    db      27,'[JV02>',0

#ifdef ELFOS
           org     7f00h
#else
#ifdef STGROM
;[RLA] The Visual/02 data segment is always just below the monitor's data page.
           org     RAMPAGE-0100h
#else
           org     7e00h
#endif
#endif

r0:        equ     $
r1:        equ     r0+2
r2:        equ     r1+2
r3:        equ     r2+2
r4:        equ     r3+2
r5:        equ     r4+2
r6:        equ     r5+2
r7:        equ     r6+2
r8:        equ     r7+2
r9:        equ     r8+2
ra:        equ     r9+2
rb:        equ     ra+2
rc:        equ     rb+2
rd:        equ     rc+2
re:        equ     rd+2
rf:        equ     re+2
q:         equ     rf+2
t:         equ     q+1
ie:        equ     t+1
last:      equ     ie+1
multi:     equ     last+2
mcount:    equ     multi+1
nbp:       equ     mcount+2
bp:        equ     nbp+1
ntraps:    equ     bp+16
traps:     equ     ntraps+1
buffer:    equ     traps+16

