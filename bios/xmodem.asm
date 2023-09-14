; *******************************************************************
; *** This software is copyright 2020 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

;[RLA] These are defined on the rcasm command line!
;[RLA] #define STGROM		; build the STG EPROM version

;[RLA] The STG EPROM version is (semi) standalone ...
#ifdef STGROM			;[RLA]
include config.inc		;[RLA] STG EPROM definitions
#endif
include bios.inc

;[RLA]   Usually the XMODEM data segment lives at the very top end of RAM, but
;[RLA] on the ELF2K or the PicoElf with the STG EPROM, the ROM monitor reserves
;[RLA] the last page of RAM and we have to squeeze in just below that.
#ifdef STGROM
base:      equ     RAMPAGE-0100h
#else
base:      equ     07f00h
#endif

; XMODEM data segment
baud:      equ     base+0
init:      equ     base+1
block:     equ     base+2            ; current block
count:     equ     base+3            ; byte send/receive count
xdone:     equ     base+4
h1:        equ     base+5
h2:        equ     base+6
h3:        equ     base+7
txrx:      equ     base+8            ; buffer for tx/rx
temp1:     equ     base+150
temp2:     equ     base+152
buffer:    equ     base+154          ; address for input buffer
ack:       equ     06h
nak:       equ     15h
soh:       equ     01h
etx:       equ     03h
eot:       equ     04h
can:       equ     18h
csub:      equ     1ah

;[RLA]   In the STG version XMODEM is an independent module and there's a table
;[RLA] of entry vectors at the start.  All the other code, including the EPROM
;[RLA] stuff like BASIC or Forth, call XMODEM via these vectors.  Needless to
;[RLA] say, these need to remain in this order and at this location!
#ifdef STGROM
	org	XMODEM	 	;[RLA] the XMODEM module lives here ...
	lbr	xopenw		;[RLA] open XMODEM channel for sending
	lbr	xopenr		;[RLA]  "    "  "   "   "   "  receiving
	lbr	xread		;[RLA] receive XMODEM data
	lbr	xwrite		;[RLA] send     "  "   "
	lbr	xclosew		;[RLA] close XMODEM sending channel
	lbr	xcloser		;[RLA]   "    "  "  receiving  "
#endif

; *******************************************
; ***** Open XMODEM channel for writing *****
; *******************************************
xopenw:    push    rf                ; save consumed register
           mov     rf,block          ; current block number
           ldi     1                 ; starts at 1
           str     rf                ; store into block number
           inc     rf                ; point to byte count
           ldi     0                 ; set count to zero
           str     rf                ; store to byte count
           mov     rf,baud           ; place to store baud constant
           ghi     re                ; need to turn off echo
           str     rf                ; save it
           ani     0feh
           phi     re                ; put it back
xopenw1:   sep     scall             ; read a byte from the serial port
           dw      f_read
           smi     nak               ; need a nak character
           lbnz    xopenw1           ; wait until a nak is received
           pop     rf                ; recover rf
           sep     sret              ; and return to caller

; ***********************************
; ***** Write to XMODEM channel *****
; ***** RF - pointer to data    *****
; ***** RC - Count of data      *****
; ***********************************
xwrite:    push    r8                ; save consumed registers
           push    ra
           mov     ra,count          ; need address of count
           ldn     ra                ; get count
           str     r2                ; store for add
           plo     r8                ; put into count as well
           ldi     txrx.0            ; low byte of buffer
           add                       ; add current byte count
           plo     ra                ; put into ra
           ldi     txrx.1            ; high byte of buffer
           adci    0                 ; propagate carry
           phi     ra                ; ra now has address
xwrite1:   lda     rf                ; retrieve next byte to write
           str     ra                ; store into buffer
           inc     ra
           inc     r8                ; increment buffer count
           glo     r8                ; get buffer count
           ani     080h              ; check for 128 bytes in buffer
           lbz     xwrite2           ; jump if not
           sep     scall             ; send current block
           dw      xsend
           ldi     0                 ; zero buffer count
           plo     r8
           mov     ra,txrx           ; reset buffer position
xwrite2:   dec     rc                ; decrement count
           glo     rc                ; see if done
           lbnz    xwrite1           ; loop back if not
           ghi     rc                ; need to check high byte
           lbnz    xwrite1           ; loop back if not
           mov     ra,count          ; need to write new count
           glo     r8                ; get the count
           str     ra                ; and save it
           pop     ra                ; pop consumed registers
           pop     r8
           sep     sret              ; and return to caller


; *******************************
; ***** Send complete block *****
; *******************************
xsend:     push    rf                 ; save consumed registers
           push    rc
xsendnak:  ldi     soh                ; need to send soh character
           phi     rc                 ; initial value for checksum
           sep     scall              ; send it
           dw      f_tty
           mov     rf,block           ; need current block number
           ldn     rf                 ; get block number
           str     r2                 ; save it
           ghi     rc                 ; get checksum
           add                        ; add in new byte
           phi     rc                 ; put it back
           ldn     r2                 ; recover block number
           sep     scall              ; and send it
           dw      f_tty
           ldn     rf                 ; get block number back
           sdi     255                ; subtract from 255
           str     r2                 ; save it
           ghi     rc                 ; get current checksum
           add                        ; add in inverted block number
           phi     rc                 ; put it back
           ldn     r2                 ; recover inverted block number
           sep     scall              ; send it
           dw      f_tty
           ldi     128                ; 128 bytes to write
           plo     rc                 ; place into counter
           mov     rf,txrx            ; point rf to data block
xsend1:    lda     rf                 ; retrieve next byte
           str     r2                 ; save it
           ghi     rc                 ; get checksum
           add                        ; add in new byte
           phi     rc                 ; save checksum
           ldn     r2                 ; recover byte
           sep     scall              ; and send it
           dw      f_tty
           dec     rc                 ; decrement byte count
           glo     rc                 ; get count
           lbnz    xsend1             ; jump if more bytes to send
           ghi     rc                 ; get checksum byte
           sep     scall              ; and send it
           dw      f_tty    
xsend2:    sep     scall              ; read byte from serial port
           dw      f_read
           str     r2                 ; save it
           smi     nak                ; was it a nak
           lbz     xsendnak           ; resend block if nak
           mov     rf,block           ; point to block number
           ldn     rf                 ; get block number
           adi     1                  ; increment block number
           str     rf                 ; and put it back
           inc     rf                 ; point to buffer count
           ldi     0                  ; set buffer count
           str     rf
           pop     rc                 ; recover registers
           pop     rf
           sep     sret               ; and return

; **************************************
; ***** Close XMODEM write channel *****
; **************************************
xclosew:   push    rf                 ; save consumed registers
           push    rc
           mov     rf,count           ; get count of characters unsent
           ldn     rf                 ; retrieve count
           lbz     xclosewd           ; jump if no untransmitted characters
           plo     rc                 ; put into count
           str     r2                 ; save for add
           ldi     txrx.0             ; low byte of buffer
           add                        ; add characters in buffer
           plo     rf                 ; put into rf
           ldi     txrx.1             ; high byte of transmit buffer
           adci    0                  ; propagate carry
           phi     rf                 ; rf now has position to write at
xclosew1:  ldi     csub               ; character to put into buffer
           str     rf                 ; store into transmit buffer
           inc     rf                 ; point to next position
           inc     rc                 ; increment byte count
           glo     rc                 ; get count
           ani     080h               ; need 128 bytes
           lbz     xclosew1           ; loop if not enough
           sep     scall              ; send final block
           dw      xsend
xclosewd:  ldi     eot                ; need to send eot
           sep     scall              ; send it
           dw      f_tty
           sep     scall              ; read a byte
           dw      f_read
           smi     06h                ; needs to be an ACK
           lbnz    xclosewd           ; resend EOT if not ACK
           mov     rf,baud            ; need to restore baud constant
           ldn     rf                 ; get it
           phi     re                 ; put it back
           pop     rc                 ; recover consumed registers
           pop     rf
           sep     sret               ; and return

; *******************************************
; ***** Open XMODEM channel for reading *****
; *******************************************
xopenr:    push    rf                 ; save consumed registers
           mov     rf,baud            ; point to baud constant
           ghi     re                 ; get baud constant
           str     rf                 ; save it
           ani     0feh               ; turn off echo
           phi     re                 ; put it back
           inc     rf                 ; point to init block
           ldi     nak                ; need to send initial nak
           str     rf                 ; store it
           inc     rf                 ; point to block number
           ldi     1                  ; expect 1
           str     rf                 ; store it
           inc     rf                 ; point to count
           ldi     128                ; mark as no bytes in buffer
           str     rf                 ; store it
           inc     rf                 ; point to done
           ldi     0                  ; mark as not done
           str     rf
            
           ldi 0                      ; setup inner delay loop
           plo rf
           phi rf
           ldi 010h                   ; setup outer delay loop
           plo re
xopenr1:   dec     rf
           glo     rf
           lbnz    xopenr1
           ghi     rf
           lbnz    xopenr1
           dec     re
           glo     re
           lbnz    xopenr1
           pop     rf                 ; recover consumed register
           sep     sret               ; and return

; ************************************
; ***** Read from XMODEM channel *****
; ***** RF - pointer to data     *****
; ***** RC - Count of data       *****
; ************************************
xread:     push    ra                 ; save consumed registers
           push    r9
           mov     ra,count           ; need current read count
           ldn     ra                 ; get read count
           plo     r9                 ; store it here
           str     r2                 ; store for add
           ldi     txrx.0             ; low byte of buffer address
           add                        ; add count
           plo     ra                 ; store into ra
           ldi     txrx.01            ; high byte of buffer address
           adci    0                  ; propagate carry
           phi     ra                 ; ra now has address
xreadlp:   glo     r9                 ; get count
           ani     080h               ; need to see if bytes to read
           lbz     xread1             ; jump if so
           sep     scall              ; receive another block
           dw      xrecv
           mov     ra,txrx            ; back to beginning of buffer
           ldi     0                  ; zero count
           plo     r9
xread1:    lda     ra                 ; read byte from receive buffer
           str     rf                 ; store into output
           inc     rf
           inc     r9                 ; increment buffer count
           dec     rc                 ; decrement read count
           glo     rc                 ; get low of count
           lbnz    xreadlp            ; loop back if more to read
           ghi     rc                 ; need to check high byte
           lbnz    xreadlp            ; loop back if more
           mov     ra,count           ; need to store buffer count
           glo     r9                 ; get it
           str     ra                 ; and store it
           pop     r9                 ; recover used registers
           pop     ra
           sep     sret               ; and return to caller

; ********************************
; ***** Receive XMODEM block *****
; ********************************
xrecv:     push    rf                 ; save consumed registers
           push    rc
xrecvnak:
xrecvlp:   sep     scall              ; receive a byte
           dw      readblk
           lbdf    xrecveot           ; jump if EOT received
           mov     rf,h2              ; point to received block number
           ldn     rf                 ; get it
           str     r2                 ; store for comparison
           mov     rf,block           ; get expected block number
           ldn     rf                 ; retrieve it
           sm                         ; check against received block number
           lbnz    xrecvnak1          ; jump if bad black number
           mov     rf,txrx            ; point to first data byte
           ldi     0                  ; checksum starts at zero
           phi     rc
           ldi     128                ; 128 bytes need to be added to checksum
           plo     rc
xrecv1:    lda     rf                 ; next byte from buffer
           str     r2                 ; store for add
           ghi     rc                 ; get checksum
           add                        ; add in byte
           phi     rc                 ; put checksum back
           dec     rc                 ; decrement byte count
           glo     rc                 ; see if done
           lbnz    xrecv1             ; jump if more to add up
           ldn     rf                 ; get received checksum
           str     r2                 ; store for comparison
           ghi     rc                 ; get computed checksum
           sm                         ; and compare
           lbnz    xrecvnak1          ; jump if bad

           mov     rf,init            ; point to init number
           ldi     ack                ; need to send an ack
           str     rf
           inc     rf                 ; point to block number
           ldn     rf                 ; get block number
           adi     1                  ; increment block number
           str     rf                 ; put it back
           inc     rf                 ; point to count
           ldi     0                  ; no bytes read from this block
           str     rf
xrecvret:  pop     rc                 ; recover consumed registers
           pop     rf
           sep     sret               ; return to caller

xrecvnak1: mov     rf,init            ; point to init byte
           ldi     nak                ; need a nak
           str     rf                 ; store it
           lbr     xrecvnak           ; need to have packet resent

xrecveot:  mov     rf,xdone           ; need to mark EOT received
           ldi     1
           str     rf
           lbr     xrecvret           ; jump to return

; *************************************
; ***** Close XMODEM read channel *****
; *************************************
xcloser:   sep     scall              ; read next block
           dw      readblk
           lbnf    xcloser            ; jump if EOT not received

           mov     rf,baud            ; need to restore baud constant
           ldn     rf                 ; get it
           phi     re                 ; put it back
           sep     sret               ; return to caller

;[RLA]   The following code needs to be on a single page, because of the bnf
;[RLA] and bnz instructions in the time sensitive loop.  Assuming this whole
;[RLA] XMODEM module started on a page boundry then there's plenty of room
;[RLA} on the current page, but if you're not so lucky then uncomment the
;[RLA] following ORG statement...
;[RLA]     org     ($+0FFh) & 0FF00h  ;[RLA] move to the start of the next page

readblk:   push    rc                 ; save consumed registers
           push    ra
           push    rd
           push    r9
           ldi     132                ; 132 bytes to receive
           plo     ra
           ldi     1                  ; first character flag
           phi     ra

           mov     rf,init            ; get byte to send
           ldn     rf                 ; retrieve it
           phi     r9                 ; Place for transmit
           mov     rf,h1              ; point to input buffer
           ghi     r9                 ; get byte
           sep     scall              ; and send it
           dw      f_tty
readblk1:  sep     scall              ; read next byte from serial port
           dw      f_read
           str     rf                  ; store into buffer
           inc     rf                  ; increment buffer
           ghi     ra                  ; get first character flag
           shr                         ; shift into df
           phi     ra                  ; and put it back
           bnf     recvgo              ; jump if not first character
           glo     re                  ; [RLA] get character
           smi     04h                 ; check for EOT
           bnz     recvgo              ; jump if not EOT
           ldi     ack                 ; ACK the EOT
           sep     scall
           dw      f_tty
           ldi     1                   ; indicate EOT received
           lbr     recvret
recvgo:    dec     ra                  ; decrement receive count
           glo     ra                  ; see if done
           bnz    readblk1             ; jump if more bytes to read
           ldi     0                   ; clear df flag for full block read
recvret:   shr
           pop     r9
           pop     rd                  ; recover consumed registers
           pop     ra
           pop     rc
           sep     sret                ; and return to caller
