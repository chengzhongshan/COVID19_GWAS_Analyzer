%macro groupsummary(
dsdin,
grps,/*grps for the by statement*/
vars4summary,/*Numeric vars subject to input functions by group*/
funcs4var,	/*functions exclusively for the proc means*/
dsdout,
include_org_dsd_in_output=1 /*add the input dsdin into the dsdout*/
);

proc sort data=&dsdin;
by &grps;

ods select none;
*assigning the output dsd with appendix of _summary will avoid of ;
*crashing the original &dsdin if &dsdout has the same name as that of &dsdin;
ods output Summary=&dsdout._summary;
proc means data=&dsdin &funcs4var;
var &vars4summary;
by &grps;
run;
ods select all;

%if &include_org_dsd_in_output=1 %then %do;
data &dsdout;
set &dsdin &dsdout._summary;
run;
%end;
%else %do;
data &dsdout;
set &dsdout._summary;
run;
%end;

%mend;


/*Demo:
		data a;
		input x y id $;
		cards;
		1 2 a
		3 4 b
		5 6 a
		10 12 a
		13 14 b
		15 16 a
		11 12 a
		13 14 b
		25 16 a
		11 21 a
		13 24 b
		15 26 a
		21 12 a
		23 14 b
		15 26 a
		21 12 a
		23 24 b
		15 16 a
;

%groupsummary(
dsdin=a,
grps=id,
vars4summary=x y,
funcs4var=median mean sum n,
dsdout=summary_out,
include_org_dsd_in_output=1
);
proc sgplot data=summary_out;
scatter x=x y=y/name='scatter';
text x=x_mean y=y_mean text=id/position=right 
                              textattrs=(size=20 weight=bold)
                              name='text';
discretelegend 'scatter';
run;

*/

