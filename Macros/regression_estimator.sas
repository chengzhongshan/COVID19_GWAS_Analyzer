%macro regression_estimator(dsdin=_last_,xvar=,yvar=,outdsd=PE);
ods graphics off;
proc reg data=&dsdin;
model &yvar=&xvar;
ods output ParameterEstimates=&outdsd;
run;
data &outdsd;
set &outdsd;
attrib Probt format=best32.;
run;
proc print;run;
%mend;

/*Demo:
*perform regression analysis with proc reg;

%regression_estimator(
dsdin=top_r4_r5(where=(cohort="HGI release 4")),
xvar=b1_z,
yvar=b2_z,
outdsd=PE
);


*/


