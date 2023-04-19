%macro Rename_Add_Prefix(oldvarlist, prefix);
  %let k=1;
  %let old = %scan(&oldvarlist, &k);
     %do %while("&old" NE "");
      rename &old = &prefix.&old;
	  %let k = %eval(&k + 1);
      %let old = %scan(&oldvarlist, &k);
  %end;
%mend;

/*
data faminc;
  input famid faminc1-faminc12 ;
cards;
1 3281 3413 3114 2500 2700 3500 3114 -999 3514 1282 2434 2818
2 4042 3084 3108 3150 -999 3100 1531 2914 3819 4124 4274 4471
3 6015 6123 6113 -999 6100 6200 6186 6132 -999 4231 6039 6215
;
run;
data a ;
  set faminc;
  %Rename_Add_Prefix(faminc1 faminc2, new_);
run;
proc print data = a heading= h noobs;
run;
*/
