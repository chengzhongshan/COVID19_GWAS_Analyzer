
%macro fmt_char_with_num(dsdin,var4fmt,var4sort,fmt_output_name,varname4fmtvar,dsdout);
/*
proc freq data=&dsdin;
table &var4fmt/noprint out=uniquevalues;
run;
*/
proc sort data=&dsdin out=uniquevalues nodupkyes;
by &var4sort;
run;

data fmtdsd;
set uniquevalues;
retain fmtname "&fmt_output_name" type 'C';
rename &var4fmt=start;
label=put(_n_,4.);
run;
proc format cntlin=fmtdsd;
run;

data &dsdout;
set &dsdin;
&varname4fmtvar=put(&var4fmt,$&fmt_output_name..);
_&varname4fmtvar._=&varname4fmtvar+0;
run;



%mend;

/*
*Demo;
data a;
input x y $;
cards;
1 a
2 b
5 c
4 d
;
run;

options mprint mlogic symbolgen;
%fmt_char_with_num(
dsdin=a,
var4fmt=y,
var4sort=x,
fmt_output_name=ngrp,
varname4fmtvar=xxx,
dsdout=out);

proc sort data=a;by y;format y $ngrp.;run;

ods graphics /width=800px height=600px;
proc sgplot data=a;
vbar y/response=x;
format y $ngrp.;
run;

*/
