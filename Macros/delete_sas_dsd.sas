%macro delete_sas_dsd(dsdin);

%if %sysfunc(exist(&dsdin)) %then %do;
 %put delete previous &dsdin;
 %if %index(&dsdin,.) %then %do;
  %let _lib_=%scan(&dsdin,1,.);
  %let _out_=%scan(&dsdin,2,.);
 %end;
 %else %do;
  %let _lib_=work;
  %let _out_=&dsdin;
 %end;

proc datasets lib=&_lib_ nolist;
delete &_out_;
run;
%end;

%mend;
/*Demo:
%delete_sas_dsd(a_norm);
*/

