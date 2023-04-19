%macro checkds(dsn);
  %if %sysfunc(exist(&dsn)) %then %do;
    proc print data = &dsn(obs=10);
    run;
  %end;
  %else %do;
    data _null_;
      file print;
      put #3 @10 "Data set &dsn. does not exist";
    run;
  %end;
%mend checkds;



/* Invoke the macro, pass a non-existent data set name to test */

*%checkds(sasuser.not_there);

/* Create a test data set and invoke the macro again, passing the data */
/* set name that does exist                                            */
/**/
/*data a;*/
/*  a=1;*/
/*run;*/
/*%checkds(work.a);*/


