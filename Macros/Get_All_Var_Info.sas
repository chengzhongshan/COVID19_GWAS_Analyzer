/*proc print data=sashelp.class;
run;
options mprint;*/

/* Save variable names, labels and formats
from dataset DATA to dataset INFO */
%macro Get_All_Var_Info(indsd,outdsd);
%let dsd_name=%scan(&indsd,-1,'.');
%let dsd_lib=%scan(&indsd,-2,'.');
/*In case of no libname was provided*/
%if %eval(&dsd_lib=) %then %let dsd_lib=work;
proc sql;
create table &outdsd as 
select name,label,format
  from dictionary.columns
  where libname=upper("&dsd_lib") and
        memname=upper("&dsd_name") and 
		memtype="DATA";
quit;
%mend;
/*
%Get_All_Var_Info(indsd=sashelp.class,outdsd=info);
*/
