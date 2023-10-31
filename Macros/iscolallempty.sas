%macro iscolallempty(dsd,colvar,outmacrovar);
%global &outmacrovar;
*Use the count function to get the number of non-empty elelments;
proc sql noprint;
select count(&colvar) 
into: allmissing
from &dsd;
quit;

%if %sysevalf(&allmissing=0,boolean) %then %do;
   %let &outmacrovar=1;
%end;
%else %do;
   %let &outmacrovar=0;
%end;

%mend;
/*Demo:

data Y71;
input pos71 $8.;
t="";
cards;
.
1
2
3
;

options mprint mlogic symbolgen;
%iscolallempty(dsd=Y71,colvar=t,outmacrovar=tot_m);
%put &tot_m;

*/
