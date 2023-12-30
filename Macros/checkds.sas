%macro checkds(dsn);
%global dsd_exist;
  %if %sysfunc(exist(&dsn)) %then %do;
    %let dsd_exist=1;
    proc print data = &dsn(obs=10);
    run;
  %end;
  %else %do;
    data _null_;
      file print;
      put #3 @10 "Data set &dsn. does not exist";
    run;
    %let dsd_exist=0;
  %end;
%mend checkds;



/* Invoke the macro, pass a non-existent data set name to test */

*%checkds(sasuser.not_there);
*%put The existence of sas dataset dsd is indicated by the global macro variable dsd_exist (Yes = 1 and No = 0);
*%put dsd_exist=&dsd_exist;

/* Create a test data set and invoke the macro again, passing the data */
/* set name that does exist                                            */
/**/
/*data a;*/
/*  a=1;*/
/*run;*/
/*%checkds(work.a);*/


