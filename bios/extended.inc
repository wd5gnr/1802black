
; Define LEAN_EXTENDED if you only want what I think are
; "important" extended words You can always load the rest as you see
; fit at runtime


; rules: All uppercase
; no multiple line definitions
; 0 Ends each string and a zero at the end
; Sometimes (but not always) RC/ASM stops after a double quote
; So '." foo " .',0  -- might stop after the quote. Check the listing to be sure

  ; You can put ASCII definitions/command here 
; But you can also use the Fxxx words for core words.
; So...
; db ': foo swap drop ;',0
; is the same as:
; db FCOLON,'foo',FSWAP,FDROP,FSEMI,0
; NOTE: tokens no longer have to end in space if there is a compiled token following. 
; Also FDOTQT is "odd":  dw FDOTQT,' <-space not printed"100 2 + ',FDOT,FCR,0
; Note the first space is "eaten" and the quote ends the string (no zero), and you do NOT need 
; a space after the quote (although it won't hurt if you have one)
; You can also use T_NUM:  db T_NUM,0,0ffh   ; 255
; or T_ASCII: db FCOLON,T_ASCII,'FOO',0,....

  

; of course, it is easy enough to move stuff from one list to the other
#ifndef LEAN_EXTENDED
  db FCOLON,'+! TUCK',FAT,FPLUS,FSWAP,FEXCL,FSEMI,0
  db FCOLON,'-! NEG +!',FSEMI,0
  db FCOLON,'*! TUCK',FAT,FMUL,FSWAP,FEXCL,FSEMI,0
  db FCOLON,'/! TUCK',FAT,FSWAP,FDIV,FSWAP,FEXCL,FSEMI,0
  db FCOLON,'/MOD 2DUP MOD',FMROT,FDIV,FSEMI,0
  db FCOLON,'@+',FDUP,FAT,FSWAP,'2+ ',FSWAP,FSEMI,0
  db FCOLON,'2DUP',FOVER,FOVER,FSEMI,0
  db FCOLON,'2DROP',FDROP,FDROP,FSEMI,0
  db FCOLON,'2OVER 3 PICK 3 PICK',FSEMI,0
  db FCOLON,'2SWAP',FGTR,FMROT,FRGT,FMROT,FSEMI,0
  db FCOLON,'ABS',FDUP,'0< ',FIF,'NEG ',FTHEN,FSEMI,0
  db FCOLON,'BYTESWAP',FDUP,'8 >>',FSWAP,'0XFF',FAND,'8 <<',FOR,FSEMI,0
  db FCOLON,'C+!',FDUP,FGTR,FCAT,FPLUS,FRGT,FCEXCL,FSEMI,0
  db FCOLON,'C-! NEG C+!',FSEMI,0
  db FCOLON,'CLRBIT 1',FSWAP,' << INVERT',FAND,FSEMI,0
  db FCOLON,'ERASE 0 FILL',FSEMI,0
  db FCOLON,'FILL',FSWAP,FGTR,FOVER,FCEXCL,FDUP,'1+',FRGT,'1-',FCMOVE,FSEMI,0
  db FCOLON,'GETBIT >> 1',FAND,FSEMI,0
  db FCOLON,'GOTOXY',FBASE,FAT,FMROT,FOPT,FAT,FMROT,T_NUM,0,10,FBASE,FEXCL,'1',FOPT,FEXCL,'ESC ." [". ." ;". ." H"',FOPT,FEXCL,FBASE,FEXCL,FSEMI,0
  db FCOLON,'J',FRPAT,'6 + @',FSEMI,0
  db FCOLON,'INVERT',T_NUM,0ffh,0ffh,FXOR,FSEMI,0
  db FCOLON,'LSHIFT',FDUP,FWHILE,FSWAP,'2',FMUL,FSWAP,'1-',FDUP,FREPEAT,FDROP,FSEMI,0
  db FCOLON,'MAX 2DUP < SWAP?',FDROP,FSEMI,0
  db FCOLON,'MIN 2DUP > SWAP?',FDROP,FSEMI,0
  db FCOLON,'RSHIFT',FDUP,FWHILE,FSWAP,'2',FDIV,FSWAP,'1-',FDUP,FREPEAT,FDROP,FSEMI,0
  db FCOLON,'SETBIT 1',FSWAP,'<<',FOR,FSEMI,0
  db FCOLON,'SGN',FDUP,FIF,'0X8000',FAND,FIF,T_NUM,0ffh,0ffh,FELSE,'1',FTHEN,FTHEN,FSEMI,0
  db FCOLON,'SWAP?',FIF,FSWAP,FTHEN,FSEMI,0 
  db FCOLON,'TGLBIT 1',FSWAP,'<<',FXOR,FSEMI,0
  db FCOLON,'UMIN 2DUP U> SWAP?',FDROP,FSEMI,0
  db FCOLON,'UMAX 2DUP U< SWAP?',FDROP,FSEMI,0
  db FCOLON,'BASEOUT',FBASE,FAT,FMROT,FBASE,FEXCL,FDOT,FBASE,FEXCL,FSEMI,0
  db FCOLON,'#.',T_NUM,0,10,'BASEOUT ;',0
  db FCOLON,'$.',T_NUM,0,16,'BASEOUT ;',0
  db FCOLON,'%.',T_NUM,80h,00,FBEGIN,'2DUP',FAND,FIF,T_NUM,0,31h,FELSE,T_NUM,0,30h
    db         FTHEN,FEMIT,'1 ',FGTGT,FDUP,'NOT',FUNTIL,'SPACE',FDROP,FDROP,FSEMI,0
  db FCOLON,'CASE?',FOVER,FEQUAL,FDUP,FIF,'NIP',FTHEN,FSEMI,0
#endif

  db  0

