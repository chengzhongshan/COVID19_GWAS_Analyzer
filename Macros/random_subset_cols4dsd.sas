%macro random_subset_cols4dsd(
dsdin,
rgx2matchcols,
rgx2fixedcols,
rnd_pct,
dsdout
);

proc contents data=&dsdin out=sampling noprint;
run;

*get fixed column names and saved them into a macro var;
*These fixed columns usually are few, so the length of macro var will not be truncated;
proc sql noprint;
select name into: fixedcols separated by ' '
from sampling
where prxmatch("/&rgx2fixedcols/",name);

*get all target columns for random selection;
data sampling(keep=vars rnd_n);
set sampling;
rnd_n=rand("uniform",0,1);
rename name=vars;
if prxmatch("/&rgx2matchcols/",name);
;
run;

proc sql noprint;
select count(*) into: totrows
from sampling;
%let totrows=%sysfunc(left(&totrows));
*Only partial columns will be selected based on the pct ;
%let sn=%sysevalf(&totrows*&rnd_pct,floor);
proc sort data=sampling out=sampling;by rnd_n;
proc sql noprint;
select vars into: var1-:var&sn
from sampling(obs=&sn);
*Subset columns by dropping some cols;
data &dsdout;
set &dsdin;
keep &fixedcols 
%do i=1 %to &sn;
 &&var&i
%end;
;
run;
%mend;
/*Demo:
option mprint mlogic symbolgen;
libname sc "/home/cheng.zhong.shan/data";
%random_subset_cols4dsd(
dsdin=sc.exp,
rgx2matchcols=%str(^V),
rgx2fixedcols=%str(^rownames),
rnd_pct=0.1,
dsdout=x
);

*/
