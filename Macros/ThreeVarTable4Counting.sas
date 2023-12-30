%macro ThreeVarTable4Counting(dsd,firstvar,secondvar,thirdvar);
/*
Make a table to count items in the following format:
firstvar would be the rownames of the table;
secondvar and thirdvar will be the 1st and 2nd column labels;
*/
%if "&thirdvar" ne "" %then %do;
proc report data=&dsd;
column &firstvar &secondvar,&thirdvar;
define &thirdvar/across;
define &firstvar/group;
define &secondvar/across;
run;
%end;
%else %do;
proc report data=&dsd;
column &firstvar &secondvar;
define &firstvar/group;
define &secondvar/across;
run;
%end;

%mend;


/*Demo codes:;

*If thirdvar="", then only make a two-way table;
%ThreeVarTable4Counting(dsd=,firstvar=,secondvar=,thirdvar=);

%ThreeVarTable4Counting(dsd=sashelp.cars,firstvar=make,secondvar=type,thirdvar=origin);

*/
