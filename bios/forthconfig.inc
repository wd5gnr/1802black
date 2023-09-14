; Configuration items

; pick EXACTLY one of the next two
#ifndef NO_BLOAD
#ifndef BLOAD_TEXT
;#define NO_BLOAD
#define BLOAD_TEXT
#endif
#endif

; If you want the entire EXTLOAD/BLOAD words to load on first start up, define this:
#define BLOAD_AUTO
; core words always load


; if you want to compile to a separate "compile buffer" define this
#ifndef NO_USE_CBUFFER
#define USE_CBUFFER
#endif
; If you turn off CBUFFER and use BLOAD_TEXT, you'll need to uncomment some code in cbload...
; Several newer features REQUIRE CBUFFER

; if you want to find the last of a multiply-defined user word instead of the first one...
; FIND_LAST is "better" Forth behavior but very inefficient
; Fixing that would require a reorg of the entire dictionary structure
; Note that you MUST define this to use option 2 below
; which allows you to pick find first OR find last, so you really should 
; never undef this under normal circumstances
#ifndef NO_FIND_LAST
#define FIND_LAST
#endif


; option bits
; 1 - Set to supress spaces after output number
; 2 - Set to search dictionary for first def instead of last def
; 4 - Set to output 4 digit hex numbers always
; 32 - SEE/LIST do not dump variable data if set
; 64 - Turn of debugging
; 128 - Turn on debugging
#ifndef DEF_OPTION
DEF_OPTION:    equ 0
#endif


; You can choose to only load core ext words into ROM by defining LEAN_EXTENDED
; If you don't do this, you get two bloads where 0 BLOAD loads the core external and 1 BLOAD loads the extended 
; On startup, both are loaded
;#define LEAN_EXTENDED

; It makes a smaller footprint to use the testop subroutine but because it is used heavily, it makes us slower
; So if you comment this out, it will go back to inline all the ones that can be inlined
; save one or two for performance or other reasons (e.g, we save the option at the same time or something)
#define OPT_BY_CALL

; If defined, selectively inline GETVAR for the same reason -- better performance, larger ROM
;#define INLINE_GETVAR
