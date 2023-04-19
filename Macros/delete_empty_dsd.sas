*options mprint symbolgen mlogic;
%macro delete_empty_dsd(dsd_in);
%if (%sysfunc(count(&dsd_in,%str(.)))>0) %then %do;
%let lib=%scan(&dsd_in,1,'.');
%let dsd_in=%scan(&dsd_in,2,'.');
%end;
%else %do;
%let lib=work;
%end;
proc sql noprint;
select count(*)
into: obs_num
from &lib..&dsd_in;
%if (&obs_num=0) %then %do;
proc datasets lib=&lib nolist;
delete &dsd_in;
run;
%put "The dataset &dsd_in in the library &lib is empty!";
%put "The above dataset is deleted!";
%end;
%mend;
/*Demo

%delete_empty_dsd(dsd_in=work.Onekg_individuals);

*/
