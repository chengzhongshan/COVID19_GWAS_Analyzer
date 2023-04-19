%macro squeez_single_num_var_length(
dsdin,
/*Note: the var in the dsdin will be squeezed, which means the output dsd would be dsdin*/
var);
%put going to reduce dsd size by using length command;
%let size=%FileAttribs(%sysfunc(getoption(work))/&dsdin..sas7bdat);
%put unreduced dsd size is &size Mb;
data _null_; 
do i=1 to 10000; 
a=trunc(i,3); 
if a ^=i then do; call symput ('max_3' , a); 
output; stop; 
end; 
end; 
run; 

proc sql noprint;
select max(&var) into: max_num_var
from &dsdin;
%let max_len=3;
%if %sysevalf( &max_num_var > &max_3 or &max_num_var < -&max_3) %then %do; 
%if %sysevalf(&max_num_var ne %sysfunc(trunc( &max_num_var, 7 ))) %then %let max_len=8; %else 
%if %sysevalf(&max_num_var ne %sysfunc(trunc( &max_num_var, 6 ))) %then %let max_len=7; %else 
%if %sysevalf(&max_num_var ne %sysfunc(trunc( &max_num_var, 5 ))) %then %let max_len=6; %else 
%if %sysevalf(&max_num_var ne %sysfunc(trunc( &max_num_var, 4 ))) %then %let max_len=5; %else 
%if %sysevalf(&max_num_var ne %sysfunc(trunc( &max_num_var, 3 ))) %then %let max_len=4;
%end; 

data &dsdin(drop=&var);
length _&var &max_len.;
set &dsdin;
_&var=&var;
run;
data &dsdin;
set &dsdin;
rename _&var=&var;
run;
%let size=%FileAttribs(%sysfunc(getoption(work))/&dsdin..sas7bdat);
%put after reduction, the dsd size is &size Mb;
%mend;
