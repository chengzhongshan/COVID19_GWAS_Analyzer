/**********************************************************
* Macro for grouping continuous variable into quantile4dsdiles.  *
* The macro requires three input variables:               *
* dsn: data set name                                      *
* var: variable to be categorised                         *
* quantile4dsdvar: name of the new variable to be created        *
*                                                         *
* Sample usage:                                           *
* %quantile4dsd(mydata.project,meat,meat_q);                     *
*                                                         *
* After running the macro, the dataset mydata.project     *
* will contain a new variable called meat_q with values   *
* . (missing), 1, 2, 3, 4, and 5.                         *
*                                                         *
* The cutpoints for the quantile4dsdiles are calculated based    *
* on all non-missing values of the variable in question.  *
*                                                         *
* To base the cutpoints for the quantile4dsdiles on, for example,*
* controls only, the code can be changed as follows:      *
* proc univariate noprint data=&dsn.(where=(control=1));  *
*                                                         *
* Paul Dickman (paul.dickman@mep.ki.se)                   *
* April 1999                                              *
**********************************************************/
%macro quantile4dsd(dsn,var,quantile4dsdvar);

/* calculate the cutpoints for the quantile4dsdiles */
proc univariate noprint data=&dsn;
  var &var;
  output out=quantile4dsdile pctlpts=20 30 40 50 60 70 80 90 pctlpre=pct;
run;

/* write the quantile4dsdiles to macro variables */
data _null_;
set quantile4dsdile;
call symput('q1',pct20) ;
call symput('q2',pct30) ;
call symput('q3',pct40) ;
call symput('q4',pct50) ;
call symput('q5',pct60) ;
call symput('q6',pct70) ;
call symput('q7',pct80) ;
call symput('q8',pct90) ;
run;

/* create the new variable in the main dataset */
data &dsn;
set &dsn;
       if &var =. then &quantile4dsdvar = .;
  else if &var le &q1 then &quantile4dsdvar=1;
  else if &var le &q2 then &quantile4dsdvar=2;
  else if &var le &q3 then &quantile4dsdvar=3;
  else if &var le &q4 then &quantile4dsdvar=4;
  else if &var le &q5 then &quantile4dsdvar=5;
  else if &var le &q6 then &quantile4dsdvar=6;
  else if &var le &q7 then &quantile4dsdvar=7;
  else if &var le &q8 then &quantile4dsdvar=8;
  else &quantile4dsdvar=9;
run;

%mend quantile4dsd;

/*
data x;
set sashelp.cars;
run;
%quantile4dsd(dsn=x,var=EngineSize,quantile4dsdvar=var_q);

*/
