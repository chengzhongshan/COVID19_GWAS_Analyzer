*****************************************************************************;
**********************  Wilcoxon Rank Sum test Macro:  **********************;
*****************************************************************************;
/*
notes/documentation

%wilcoxon(indata=test6, outdata=out_wilcox1, var=ser_plan ser_atts, class=group, by=sex, print=Y);
%wilcoxon(indata=test6, outdata=out_wilcox, var=ser_atts, class=group, print=Y);

indata:		name of input dataset

outdata:	name of output dataset

var:		continuous variables to analyze

class:		variable that defines the 2 classes, must be included, must have 2 levels

by:			optional grouping variable, do analysis within each group

print:		set to "Y" by default, specifying anything else will suppress printed summary

output variable suffixes:
1 denotes the first level when sorted ascending
0 denotes the second level when sorted ascending
*/

*---------------------------------------------------------------------------*;
********************************** Macros: **********************************;
*---------------------------------------------------------------------------*;

%macro wilcoxon(indata=, outdata=, var=, class=, by=, print=Y);
run; ods listing close; run;


*----------------------------------------------------*;
*** Run NPAR1WAY to perform wilcoxon rank sum test ***;
%if &by^=  %then %do;
proc sort data=&indata;
by &by;
%end;

proc npar1way data=&indata;
by &by;
class &class;
var &var;
ods output WilcoxonScores=_ws WilcoxonTest=_wt;
run;

run; ods listing; run;
*----------------------------------------------------*;


*--------------------------------------------------------*;
*** Double transpose wilcoxon statistics dataset (_ws) ***;
data _ws;
set _ws;
length variable $ 32;
if variable=" " then variable="&var";
order=mod(_n_,2);

proc sort data=_ws;
by &by variable class order;
proc transpose data=_ws out=_t_ws;
by &by variable class order;
var n sumofscores expectedsum stddevofsum meanscore;

data _t_ws;
set _t_ws;
length id $ 50;
id=compress(_name_,' ')||'_'||compress(order,' ');
run;

proc sort data=_t_ws;
by &by variable;
proc transpose data=_t_ws out=_tt_ws;
by &by variable;
id id;
var col1;
run;
*--------------------------------------------------------*;


*-------------------------------------------*;
*** Transpose wilcoxon test dataset (_wt) ***;
data _wt;
set _wt;
if nvalue1>.;
length variable $ 32;
if variable=" " then variable="&var";

proc sort data=_wt;
by &by variable;
proc transpose data=_wt out=_t_wt;
by &by variable;
id name1;
var nValue1;
run;

data _t_wt(keep= P2_WIL PR_WIL PT2_WIL PTR_WIL Variable Z_WIL _NAME_ _WIL_ &by);
set _t_wt;
if .<pl_wil then pr_wil=pl_wil;
if .<ptl_wil then ptr_wil=ptl_wil;
run;
*-------------------------------------------*;


*--------------------------------*;
*** Merge final output dataset ***;
data &outdata(drop= _name_);
merge _tt_ws _t_wt;
by &by variable;
label  _WIL_='Wilcoxon Statistic' Z_WIL='Normal approx. Z (Wilcox)' 
 P2_WIL='Normal approx. 2-Sided Pr > |Z| (Wilcox)'
 PT2_WIL='t approx. 2-Sided Pr > |Z| (Wilcox)'
 PR_WIL='Normal approx. 1-Sided Pr >  Z (Wilcox)' 
 PTR_WIL='t approx. 1-Sided Pr >  Z (Wilcox)' 
 ExpectedSum_1='Expected Under H0, level 1 (Wilcox)' MeanScore_1='Mean Score, level 1 (Wilcox)' 
 N_1='n, level 1' N_0='n, level 2' StdDevOfSum_1='Std Dev Under H0, level 1 (Wilcox)' 
 SumOfScores_1='Sum of Scores, level 1 (Wilcox)' 
 ExpectedSum_0='Expected Under H0, level 2 (Wilcox)' 
 MeanScore_0='Mean Score, level 2 (Wilcox)'
 StdDevOfSum_0='Std Dev Under H0, level 2 (Wilcox)' 
 SumOfScores_0='Sum of Scores, level 2 (Wilcox)'
 variable='Analysis variable';
rename n_1=n_1_npar n_0=n_0_npar;
run;
*--------------------------------*;


*-----------------------------*;
*** optional printed output ***;
%if &print=Y %then %do;
proc print data=&outdata noobs l;
var variable n_1_npar n_0_npar meanscore_1 meanscore_0 sumofscores_1 sumofscores_0 expectedsum_1 
 expectedsum_0 stddevofsum_1 stddevofsum_0  _WIL_ Z_WIL P2_WIL PT2_WIL PR_WIL PTR_WIL;
run;
%end;
*-----------------------------*;


*--------------------------------------------*;
**delete temporary working datasets in macro**;
proc datasets library=work nolist nowarn;
delete _wt _ws _t_ws _tt_ws _t_wt;
run;
quit;
*--------------------------------------------*;

%mend;

run;
*-------------------------------------------------------------------------------*;
*-------------------------------------------------------------------------------*;
*****************************************************************************;
