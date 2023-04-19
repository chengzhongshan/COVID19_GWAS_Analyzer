
%macro histogram_in_svg(dsd,numvars,scale=1);
%let i=1;
%do %while (%scan(&numvars,&i,' ') ne );
%let numvar=%scan(&numvars,&i,' ');
options printerpath=(svg out) nobyline;
filename out "&numvar..histogram.svg";
ods listing close;
ods printer;
proc sgplot data=&dsd noborder nowall;

%if &scale=1 %then %do;
histogram &numvar/scale=count;
%end;
%else %do;
histogram &numvar;
%end;

run;
ods printer close;
ods listing;
%let i=%eval(&i+1);
%end;
%mend;

/*

%get_num_or_char_vars4dsd(indsd=sashelp.cars,outdsd=info,numeric=1);
proc sql noprint;
select name into: var_names separated by ' '
from info;
%put &var_names;

%histogram_in_svg(dsd=sashelp.cars,numvars=&var_names);

*/




