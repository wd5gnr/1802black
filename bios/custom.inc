; This file can hold definitions you don't want in the "standard" definitions
   db ': INIT HEX ;',0
#ifdef LEAN_EXTENDED
  db FCOLON,'BASEOUT',FBASE,FAT,FMROT,FBASE,FEXCL,FDOT,FBASE,FEXCL,FSEMI,0
  db FCOLON,'#.',T_NUM,0,10,'BASEOUT ;',0
  db FCOLON,'$.',T_NUM,0,16,'BASEOUT ;',0
  db FCOLON,'%.',T_NUM,80h,00,FBEGIN,'2DUP',FAND,FIF,T_NUM,0,31h,FELSE,T_NUM,0,30h
  db         FTHEN,FEMIT,'1 ',FGTGT,FDUP,'NOT',FUNTIL,'SPACE',FDROP,FDROP,FSEMI,0
#endif
; breakpoint for 1802BLACK

   db ': BLKBRK ',T_NUM, 068h, 0d5h, FSPAT, FEXEC, FDROP, FDROP, FSEMI,0
   db ': STGBRK ',T_NUM,0d5h, 00h, T_NUM,079h,0d1h,FSPAT,FEXEC,FDROP,FDROP,FDROP,FSEMI,0
   db ': BASE? ." 0#"BASE @ #. ',FSEMI,0


; do not put final zero here!



