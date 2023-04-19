%macro bed4seriesplot(dsdin,chr_var,st_var,end_var,othervars4keep,dsdout);
data _bed4series_;
set &dsdin(keep=&chr_var &st_var &end_var &othervars4keep);
array X{2} &st_var &end_var;
do i=1 to 2;
		pos=X{i};
		ord=_n_;
		output;
end;
drop i &st_var &end_var;
run;
proc sql noprint;
select max(ord) into: tot_ords
from _bed4series_;

*Note: the running order for rename, keep, and where is as follows:;
*(1) keep;
*(2) rename;
*(3) where;
*So the above order will affect the codes for rename, keep, and where;
*if some of these variables were used by different codes;

data &dsdout;
set
  %do i=1 %to &tot_ords;
      _bed4series_( 
           rename=(pos=pos&i ord=ord&i) 
											keep=&chr_var pos ord &othervars4keep
											where=(ord&i=&i)
       )
		%end;
;
run;

*Need to make all missing ord&i as the number of &i;
*This will prevent the missing ord as a new group draw in the legend of the seriesplot;
data &dsdout;
set &dsdout;
%do gi=1 %to &tot_ords;
	if ord&gi=. then ord&gi=&gi;
%end;
run;
%mend;
/*Demo:
data exons;
input chr $ st end val;
cards;
chr1 10 100 4
chr1 200 300 5
chr1 400 500 6
chr1 700 900 7
chr1 1000 2000 8
;

options mprint mlogic symbolgen;
%bed4seriesplot(
dsdin=exons,
chr_var=chr,
st_var=st,
end_var=end,
othervars4keep=val,
dsdout=exons_out
);

proc sgplot data=exons_out;
series x=pos1 y=val/name="s1" group=ord1 lineattrs=(thickness=10 color=red);
series x=pos2 y=val/name="s2" group=ord2 lineattrs=(thickness=10 color=blue);
series x=pos3 y=val/name="s3" group=ord3 lineattrs=(thickness=10 color=pink);
series x=pos4 y=val/name="s4" group=ord4 lineattrs=(thickness=10 color=green);
series x=pos5 y=val/name="s5" group=ord5 lineattrs=(thickness=10 color=dark);
descretelegend "s1" "s2" "s3" "s4" "s5";
run;


*Alternatively, using group option would be easy to draw multiple bed regions in different color;
data exons;
input chr $ st end val;
array X{2} st end;
do i=1 to 2;
 pos=X{i};
 ngrp=_n_;
 output;
end;
cards;
chr1 10 100 4
chr1 200 300 5
chr1 400 500 6
chr1 700 900 7
chr1 1000 2000 8
;
proc print;run;
proc sgplot data=exons;
series x=pos y=val/name="s" group=ngrp lineattrs=(thickness=10);
descretelegend "s";
run;
*/
