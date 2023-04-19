
%macro opends(name);
%if %sysfunc(exist(&name)) %then
   %let dsid=%sysfunc(open(&name,i));
%else %put Data set &name does not exist.;
%mend opends;
/*%let dsname=sasuser.houses;*/
/*%opends(&dsname);*/
