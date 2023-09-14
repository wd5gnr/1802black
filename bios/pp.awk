BEGIN {  #configure here
# RCASM hates tabs
	 SP=" "      # the space character
	 LBLWIDTH=14 # pad out labels to this length
	 OPWIDTH=14   # pad out opcodes to this length
	 ARGWIDTH=20 # argument padding
	 OLINE=""
}    

function emit(l) {
	 sub(/[ \t]+$/,"",l);
	 if (l!="") print l;
}


     {
	 emit(OLINE);
	 OLINE=""
	 COMMENT=""
     }

END {
	 emit(OLINE);
     }

 function dopad(op,n) { # make opcode at least so long
     sub(/[ \t]+$/,"",op);  # eat trailing blanks
     if (length(op)>=n) return op " " ;   # make sure there is one space at least
     for (i=0;i<n;i++) op=op " ";
    return substr(op,1,n);   # make field 6 wide
}


     /^[ \t]*$/  {
	 next   # eat blanks
     }


# test for a whole line comment before we eat it
# case 3
/^;/ {
     OLINE=$0
     next;
     }
/^[ \t]*;/ {
           sub(/^.*;/,";");
           OLINE= dopad("",LBLWIDTH) $0
           next
           }


/(^;)|([^'];)/   {
	 COMMENT=$0
	 sub(/^[^;]*;[ \t]*/,"",COMMENT);
	 sub(/;.*$/,"");
	 if (COMMENT!="") COMMENT=SP "; " COMMENT
     }


# four cases:
# 1st chararacter = #  (preprocessor)
# 1st character = symbol character (label)
# 1st non-blank is ; (comment)
# everything else (ordinary line)

#case1 (first because it has priority)
/^#/  {
    OLINE=dopad($1,LBLWIDTH) dopad($2,OPWIDTH)  dopad($3,ARGWIDTH) COMMENT
       next
       }

# case2
/^[^[^ \t]+:$/    {     # label by itself
      OLINE=dopad($1,LBLWIDTH+OPWIDTH+ARGWIDTH) COMMENT;
      next;
  }

/^[^ \t]+:/  {   # rcasm doesn't allow indent labels
             # line with label
        LABEL=$1
	OLINE=dopad(LABEL,LBLWIDTH) dopad($2,OPWIDTH) dopad($3 " " $4 " " $5 " " $6 " " $7,ARGWIDTH) COMMENT;
       next
       }


# case 4
       {
	   OLINE=dopad("",LBLWIDTH) dopad($1,OPWIDTH) dopad($2 " " $3 " " $4 " " $5 " " $6,ARGWIDTH) COMMENT;
       next;
       }
