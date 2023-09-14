function check() {
    page=substr($2,1,2);
    tgt=$4;
    v1=substr($2,3,2)
    v2=$5

    v1d=strtonum("0x" v1)
    v2d=strtonum("0x" v2)


# what we probably really want is to understand which
# lines have page offsets between 20 and e0 since any more
# makes them likely to churn
# but I don't have any great ideas on an easy way to do that
# brute force will be to pull the low addresses and convert to dec
# then do the comparsion    


# comment the next two lines if you want everything
    if (v1d<0x20 || v2d<0x20) next
    if (v1d>0xE0||v2d>0xE0) next
    if (page==tgt) print;
}



/lb(r|z|d|n|q)/ { check(); }
