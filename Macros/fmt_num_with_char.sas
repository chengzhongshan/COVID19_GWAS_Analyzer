
%macro fmt_num_with_char(dsdin,numvar4fmt,charvar4fmt,fmt_output_name);
/*
*No need this;
proc freq data=&dsdin;
table &var4fmt/noprint out=uniquevalues;
run;
*/
proc sort data=&dsdin out=uniquevalues nondupkeys;
by &numvar4fmt;
run;

data fmtdsd;
set uniquevalues;
retain fmtname "&fmt_output_name" type 'N';
rename &numvar4fmt=start;
label=&charvar4fmt;
run;
proc format cntlin=fmtdsd;
run;

/*
*No need this, too!;
data &dsdout;
set &dsdin;
&varname4fmtvar=put(&var4fmt,$&fmt_output_name..);
_&varname4fmtvar._=&varname4fmtvar+0;
run;
*/

%mend;

/*
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/proc/n1e19y6lrektafn1kj6nbvhus59w.htm;
*Demo;
data a;
input x y $ z;
cards;
1 a 10
2 b 100
5 c 40
4 d 50
;
run;

options mprint mlogic symbolgen;
%fmt_num_with_char(
dsdin=a,
numvar4fmt=x,
charvar4fmt=y,
fmt_output_name=ngrp);

proc sort data=a;by x;format x ngrp.;run;

ods graphics /width=800px height=600px;
proc sgplot data=a;
vbar x/response=z;
format x ngrp.;
run;

*/
