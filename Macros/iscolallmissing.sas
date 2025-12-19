%macro iscolallmissing(dsd,colvar,outmacrovar);
%global &outmacrovar;
proc sql noprint;
select nmiss(&colvar)/count(&colvar) 
into: allmissing
from &dsd;
quit;

%if %sysevalf(&allmissing=1,boolean) %then %do;
   %let &outmacrovar=1;
%end;
%else %do;
   %let &outmacrovar=0;
%end;

*This rescues the situation when all data of the column &colvar are missing;
%if &allmissing=. %then %do;
   %let &outmacrovar=1;
 %end;

%mend;
/*Demo:

data Y71;
input pos71;
cards;
.
1
2
3
;

options mprint mlogic symbolgen;
%iscolallmissing(dsd=Y71,colvar=pos71,outmacrovar=tot_m);
%put &tot_m;

*/
