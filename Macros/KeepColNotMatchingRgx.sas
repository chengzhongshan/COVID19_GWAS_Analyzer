/* Apply variable names, labels and formats
from dataset indsd to target_dsd */
*options mprint;
%macro KeepColNotMatchingRgx(indsd,Rgx,outdsd);
%let dsd_name=%scan(&indsd,-1,'.');
%let dsd_lib=%scan(&indsd,-2,'.');
proc sql noprint;
create table temp as 
select name,label,format
  from dictionary.columns
  where libname=upper("&dsd_lib") and
        memname=upper("&dsd_name") and 
		memtype="DATA";
data temp(where=(g=1));
set temp;
g=1;
if prxmatch("/&Rgx/",name) then g=0;
run;

proc sql noprint;
      select name into: kept_vars separated by ' '
      from temp;

data &outdsd;
set &indsd;
keep &kept_vars;
run;

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

options mprint;
%KeepColNotMatchingRgx(indsd=work.faminc,Rgx=(faminc1|faminc12),outdsd=y);

proc print data = faminc heading= h noobs;
run;
quit;
*/
