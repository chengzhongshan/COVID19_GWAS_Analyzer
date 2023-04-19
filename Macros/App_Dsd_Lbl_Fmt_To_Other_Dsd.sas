/* Apply variable names, labels and formats
from dataset indsd to target_dsd */
*options mprint;
%macro App_Dsd_Lbl_Fmt_To_Other_Dsd(indsd,target_dsd);
%let dsd_name=%scan(&indsd,-1,'.');
%let dsd_lib=%scan(&indsd,-2,'.');
proc sql noprint;
create table temp as 
select name,label,format
  from dictionary.columns
  where libname=upper("&dsd_lib") and
        memname=upper("&dsd_name") and 
		memtype="DATA";

data temp;
set temp;
if label="" then label=name;
run;

proc sql noprint;
   select count(*) into :n from temp;
   select cat('label ',strip(name),
              '= "',strip(label),
              '"; format ',strip(name),
              ' ',strip(format),';')
      into :l1 - %sysfunc(compress(:l&n))
      from temp;
quit;

data &target_dsd;
   set &target_dsd;
   %do i = 1 %to &n; 
     &&l&i 
   %end;
run;

%mend;
/*
data toy;
set sashelp.cars;
label MPG_City="x";
run;

%App_Dsd_Lbl_Fmt_To_Other_Dsd(indsd=sashelp.cars,target_dsd=toy);

*/


