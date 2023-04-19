%macro scale4range(dsdin=,
ids=,
vars=,
factor4mult=1,
round_or_not=1,
outdsd=
);
%if &ids ne %then %do;
 proc sort data=&dsdin out=&outdsd._srted;
 by &ids;
 run;
%end;

proc stdize data=&outdsd._srted method=range mult=&factor4mult out=&outdsd;
var &vars;
%if &ids ne %then %do;
by &ids;
%end;
run;

%if &round_or_not=1 %then %do;
data &outdsd;
set &outdsd;
%let i=1;
%let var=%scan(&vars,&i,%str( ));
 %do %while (&var ne );
  &var=round(&var);
  %let i=%eval(&i+1);
  %let var=%scan(&vars,&i,%str( ));
 %end;
%end;
run;
/* proc print data=_last_(obs=10);run; */

%mend;


/*Demo:

%importallmacros;

%scale4range(
dsdin=sashelp.baseball,
ids=team,
vars=crhits,
factor4mult=1000,
round_or_not=1,
outdsd=scaled_baseball
);

*Make a panel of plots with the same xaxis;
proc sgpanel data=scaled_baseball;
panelby team;
scatter x=crhits y=salary;
run;

*/

