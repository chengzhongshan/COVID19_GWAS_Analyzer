%MACRO ExpandVarList(data=_LAST_, var=_ALL_);
%if %upcase(%superq(data)) = _LAST_
%then %let data = &SYSLAST;
%let rc = %sysfunc(dosubl(%str(
proc transpose data=&DATA(obs=0) out=ExpandVarList_temp;
var &VAR;
run;
proc sql noprint;
select _name_ into :temp_varnames separated by ' '
from ExpandVarList_temp
;
drop table ExpandVarList_temp;
quit
)));
&temp_varnames
%MEND ExpandVarList;
/*
proc print data=sashelp.cars(obs=10);run;
%let varlist=%ExpandVarList(data=sashelp.cars,var=_ALL_);
%put &varlist;
*/
