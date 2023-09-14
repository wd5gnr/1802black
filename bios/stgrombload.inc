; variables
#ifdef EBLOCK
  db 7Eh,0FFh,7Dh,0EDh,7Ch,0FFh,07h,0FEh,                                   
  db 7Ch,0FFh,0C0h,0A4h,0B9h,12h,0A6h,0DCh,                                   
  db 40h,00h,0ah,

  ; words
include wordsram0.inc
#endif
