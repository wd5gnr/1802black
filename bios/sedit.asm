; *******************************************************************
; *** This software is copyright 2005 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

#ifdef STGROM
include config.inc
	org	SEDIT
#else
           org     0dd00h
#endif
include    bios.inc


;           ldi     0
;           phi     r2
;           ldi     0ffh
;           plo     r2
;           sex     r2
           ldi     high start
           phi     r6
           ldi     low start
           plo     r6
           lbr     f_initcall


start:     ldi     high sector         ; point to base page
           phi     rb
           ldi     low sector          ; need to indicate invalid sector
           plo     rb
           ldi     0ffh                ; indicate no sector loaded
           str     rb                  ; write to pointer
           inc     rb
           str     rb
           ldi     0                   ; reset drive
           plo     rd
           sep     scall
           dw      f_idereset


mainlp:    ldi     high prompt         ; get address of prompt
           phi     rf
           ldi     low prompt
           plo     rf
           sep     scall               ; display prompt
           dw      f_msg
           sep     scall
           dw      loadbuf
           sep     scall               ; get input from user
           dw      f_input
           sep     scall
           dw      docrlf
           sep     scall
           dw      loadbuf
           lda     rf                  ; get command byte
           plo     re                  ; keep a copy
           smi     'L'                 ; check for display Low command
           lbz     disp_lo             ; jump if so
           glo     re                  ; recover command
           smi     'H'                 ; check for display high command
           lbz     disp_hi             ; jump if so
           glo     re                  ; recover command
           smi     'R'                 ; check for read sector command
           lbz     rd_sec              ; jump if so
           glo     re                  ; recover command
           smi     'N'                 ; check for next sector command
           lbz     nxt_sec             ; jump if so
           glo     re                  ; recover command
           smi     'P'                 ; check for previous sector command
           lbz     prv_sec             ; jump if so
           glo     re                  ; recover command
           smi     'D'                 ; check for display current sector
           lbz     dsp_sec             ; jump if so
           glo     re                  ; recover command
           smi     'E'                 ; check for enter bytes command
           lbz     enter               ; jump if so
           glo     re                  ; recover command
           smi     'W'                 ; check for write sector command
           lbz     write               ; jump if so
           glo     re                  ; recover command
           smi     'Q'                 ; check for quit command
           lbz     quit                ; jump if so
           glo     re                  ; recover command
           smi     'A'                 ; check for read AU command
           lbz     rd_au               ; jump if so
           glo     re                  ; recover command
           smi     'C'                 ; check for read AU chain command
           lbz     chain               ; jump if so

           lbr     mainlp

quit:      sep     sret                ; return to Elf/OS

disp_hi:   ldi     0                   ; setup address
           plo     r9
           plo     rc                  ; setup counter
           ldi     1
           phi     r9
           ldi     high (secbuf+256)   ; point to sector buffer
           phi     ra
           ldi     low (secbuf+256)
           plo     ra
           lbr     disp_ct             ; process display
disp_lo:   ldi     0                   ; setup address
           phi     r9
           plo     r9
           plo     rc                  ; setup counter
           ldi     high secbuf         ; point to sector buffer
           phi     ra
           ldi     low secbuf
           plo     ra
disp_ct:   ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           ldi     high ascbuf         ; point to ascii buffer
           phi     r7
           ldi     low ascbuf
           plo     r7
           ldi     0                   ; initial line is empty
           str     rf
           str     r7
disp_lp:   glo     rc                  ; get count
           ani     0fh                 ; need to see if on 16 byte boundary
           lbnz    disp_ln             ; jump to display line
           ldi     0                   ; place terminator
           str     rf
           str     r7
           ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           sep     scall               ; output the last line
           dw      f_msg
           ldi     high ascbuf         ; point to ascii buffer
           phi     rf
           ldi     low ascbuf
           plo     rf
           sep     scall               ; output the last line
           dw      f_msg
           sep     scall
           dw      docrlf
           ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           ldi     high ascbuf         ; point to ascii buffer
           phi     r7
           ldi     low ascbuf
           plo     r7
           ghi     r9                  ; get address
           phi     rd                  ; and get for hexout
           glo     r9
           plo     rd
           sep     scall               ; output the address
           dw      f_hexout4
           ldi     ':'                 ; colon following address
           str     rf
           inc     rf
           ldi     ' '                 ; and a space
           str     rf
           inc     rf
           glo     r9                  ; increment address
           adi     16
           plo     r9
           ghi     r9
           adci    0
           phi     r9
disp_ln:   lda     ra                  ; get next byte
           plo     re                  ; keep a copy
           ani     0e0h                ; check for values below 32
           lbz     dsp_dot             ; display a dot
           ani     080h                ; check for high values
           lbnz    dsp_dot
           glo     re                  ; recover original character
           lbr     asc_go              ; and continue
dsp_dot:   ldi     '.'                 ; place dot into ascii buffer
asc_go:    str     r7                  ; store into buffer
           inc     r7                  ; and increment
           glo     re                  ; recover value
           plo     rd                  ; setup for output
           sep     scall               ; convert it
           dw      f_hexout2
           ldi     ' '                 ; space after number
           str     rf
           inc     rf
           dec     rc                  ; decrement count
           glo     rc                  ; get count
           lbnz    disp_lp             ; loop back if more to go
           ldi     0                   ; place terminator
           str     rf
           str     r7
           ldi     high outbuf         ; point to output buffer
           phi     rf
           ldi     low outbuf
           plo     rf
           sep     scall               ; output the last line
           dw      f_msg
           ldi     high ascbuf         ; point to ascii buffer
           phi     rf
           ldi     low ascbuf
           plo     rf
           sep     scall               ; output the last line
           dw      f_msg
           sep     scall
           dw      docrlf
           lbr     mainlp              ; back to main loop

rd_au:     sep     scall               ; convert au number
           dw      f_hexin
           ldi     3                   ; need to shift by 3
           plo     rc
au_lp:     glo     rd                  ; multiply by 2
           shl
           plo     rd
           ghi     rd
           shlc
           phi     rd
           dec     rc                  ; decrement count
           glo     rc                  ; see if done
           lbnz    au_lp               ; loop back if not
           lbr     readit              ; read first sector of au
rd_sec:    sep     scall               ; convert sector number
           dw      f_hexin
readit:    ldi     low sector          ; point to sector number
           plo     rb
           ghi     rd                  ; and write sector address
           str     rb
           inc     rb
           glo     rd
           str     rb
           ghi     rd                  ; prepare for sector read
           phi     r7
           glo     rd
           plo     r7
           ldi     0
           plo     r8
           ldi     0e0h                ; in lba mode
           phi     r8
           ldi     high secbuf         ; point to sector buffer
           phi     rf
           ldi     low secbuf
           plo     rf
           sep     scall               ; read the sector
           dw      f_ideread
           lbdf    ide_error
           lbr     dsp_sec

write:     ldi     low sector          ; point to sector number
           plo     rb
           lda     rb                  ; and read it
           phi     r7
           lda     rb
           plo     r7
           ldi     0
           plo     r8
           ldi     0e0h                ; in lba mode
           phi     r8
           ldi     high secbuf         ; point to sector buffer
           phi     rf
           ldi     low secbuf
           plo     rf
           sep     scall               ; write the sector
           dw      f_idewrite
           lbnf    dsp_sec             ; jump if no error occurred
ide_error: stxd                        ; save error code
           sep     scall               ; display error message
           dw      f_inmsg
           db      'Error on drive: ',0
           ldi     high buffer         ; point to buffer
           phi     rf
           ldi     low buffer
           plo     rf
           irx                         ; recover error code
           ldx
           plo     rd
           sep     scall               ; display it
           dw      f_hexout2
           ldi     0                   ; terminate value
           str     rf
           ldi     high buffer         ; point to buffer
           phi     rf
           ldi     low buffer
           plo     rf
           sep     scall               ; display code
           dw      f_msg
           sep     scall
           dw      f_inmsg
           db      10,13,0
           lbr     mainlp              ; then back to main loop
 
nxt_sec:   ldi     low sector          ; point to current sector number
           plo     rb
           lda     rb                  ; and read it
           phi     rd
           lda     rb
           plo     rd
           inc     rd                  ; increment sector number
           lbr     readit              ; and read new physical sector

prv_sec:   ldi     low sector          ; point to current sector number
           plo     rb
           lda     rb                  ; and read it
           phi     rd
           lda     rb
           plo     rd
           dec     rd                  ; decrement sector number
           lbr     readit              ; and read new physical sector

dsp_sec:   ldi     high sec_msg        ; display message
           phi     rf
           ldi     low sec_msg
           plo     rf
           sep     scall               ; and display it
           dw      f_msg
           ldi     low sector          ; get current sector number
           plo     rb
           lda     rb                  ; and retrieve it
           phi     rd
           lda     rb
           plo     rd
           sep     scall               ; point to buffer
           dw      loadbuf
           sep     scall               ; convert sector number
           dw      f_hexout4
           ldi     0                   ; write terminator
           str     rf
           sep     scall               ; point to buffer
           dw      loadbuf
           sep     scall               ; and display it
           dw      f_msg
           sep     scall               ; carriage return
           dw      docrlf
           lbr     mainlp              ; back to main loop

enter:     sep     scall               ; convert address
           dw      f_hexin
           glo     rd                  ; transfer address
           adi     low secbuf          ; add in sector buffer offset
           plo     ra
           ghi     rd
           adci    high secbuf
           phi     ra
enter_lp:  sep     scall               ; move past whitespace
           dw      f_ltrim
           ldn     rf                  ; see if at terminator
           lbz     mainlp              ; jump if done
           sep     scall               ; otherwise convert number
           dw      f_hexin
           glo     rd                  ; get number
           str     ra                  ; write into sector
           inc     ra                  ; point to next position
           lbr     enter_lp            ; and look for more

chain:     sep     scall               ; convert address
           dw      f_hexin
           ghi     rd                  ; transfer address
           phi     ra
           glo     rd
           plo     ra
chain_lp:  sep     scall               ; read specified lump
           dw      readlump
           ghi     ra                  ; transfer for display
           phi     rd
           glo     ra
           plo     rd
           sep     scall               ; setup buffer
           dw      loadbuf
           sep     scall               ; convert number
           dw      f_hexout4
           ldi     ' '                 ; need a space
           str     rf
           inc     rf
           ldi     0                   ; and terminator
           str     rf
           sep     scall               ; setup buffer
           dw      loadbuf
           sep     scall               ; display it
           dw      f_msg
           glo     ra                  ; check for nonzero entry
           lbnz    chain_nz            ; jump if not
           ghi     ra
           lbnz    chain_nz
chain_dn:  sep     scall               ; display a CR/LF
           dw      docrlf
           lbr     mainlp              ; and back to main loop
chain_nz:  glo     ra                  ; check for end of chain code
           smi     0feh
           lbnz    chain_ne            ; jump if not end
           ghi     ra
           smi     0feh
           lbz     chain_dn            ; jump if end of chain
chain_ne:  glo     ra                  ; check for invalid entry
           xri     0ffh
           lbnz    chain_lp            ; jump if not
           ghi     ra
           xri     0ffh
           lbnz    chain_lp
           lbr     chain_dn
loadbuf:   ldi     high buffer
           phi     rf
           ldi     low buffer
           plo     rf
           sep     sret

docrlf:    ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      f_msg
           sep     sret

lmpsecofs: glo     ra                  ; get low byte of lump
           shl                         ; multiply by 2
           plo     r9                  ; put into offset
           ldi     0
           shlc                        ; propagate carry
           phi     r9                  ; R9 now has lat offset
           ghi     ra                  ; get high byte of lump
           adi     17                  ; add in base of lat table
           plo     r7                  ; place into r7
           ldi     0
           adci    0                   ; propagate the carry
           phi     r7
           ldi     0                   ; need to zero R8
           phi     r8
           plo     r8
           sep     sret                ; return to caller

readlump:  sep     scall               ; convert lump to sector:offset
           dw      lmpsecofs
           ldi     high secbuf2        ; point to buffer
           phi     rf
           ldi     low secbuf2
           plo     rf
           sep     scall               ; read the sector
           dw      f_ideread
           glo     r9                  ; point to entry
           adi     low secbuf2
           plo     rf
           ghi     r9
           adci    high secbuf2
           phi     rf
           lda     rf                  ; and retrieve entry
           phi     ra
           lda     rf
           plo     ra
           sep     sret                ; and return

; [RLA]   You have to write out the "SEDIT>" prompt in this rather awkward way
; [RLA] because rc/asm will do macro subsitutions inside of literal strings.
; [RLA] Since the STGROM defines "SEDIT" as the address for this program, you'll
; [RLA] with a prompt that looks like "CD00>"!  Not good...
prompt:    db      'S','E','D','I','T','>',0
crlf:      db      10,13,0
sec_msg:   db      'Current sector: ',0


           org     0100h
sector:    ds      2
buffer:    ds      256
ascbuf:    ds      80
outbuf:    ds      80
secbuf:    ds      512
secbuf2:   ds      512
