  ; RAM BLOAD



#ifdef EBLOCK

; something prevents this from being automatically calculated, so:
; You need to adjust the numbers below:
; If your ORG is 6600 you need 65, 64, and 63 twice

  db 065h    ; ORG.1-1
  db 0FFh
  db 064h    ; ORG.1-2
  db 0EDh
  db 063h    ; ORG.1-3
  db 0FFh,07h,0FEh,           
  db 063h    ; ORG.1-3 again
  db 0FFh,0C0h,0A4h,0B9h,12h,0A6h,0DCh, 40h,00h,0ah,

include wordsram0.inc
  
#endif