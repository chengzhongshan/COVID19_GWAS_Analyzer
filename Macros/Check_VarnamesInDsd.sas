%macro Check_VarnamesInDsd(indsd=,Rgx=.,exist_tag=);

%global &exist_tag;
%let &exist_tag=;
%put Your input sas dsd is &indsd;

*Add quit here to quit process that may prevent the script from running proc contents;
quit;
%put Going to run proc contents to obtain variable list!;
proc contents data=&indsd out=_tmp_(keep=name type) print;
run;

%if not %sysfunc(exist(_tmp_)) %then %do;
  %put The proc contents failed to generate variable table!;
  %abort 255;
%end;

data _tmp_1;
set _tmp_;
if prxmatch("/&Rgx/i",name);
run;
proc sql noprint;
select name into: &exist_tag separated by ' '
from _tmp_1;
%put Your rgx (&Rgx) matchs the following vars:;
%put &&&exist_tag;
%put A global macro var &exist_tag is created to have the varnames;

%if %length(&&&exist_tag)=0 %then %do;
  %put No varnames matching with your Rgx (&Rgx);
  %abort 255;
%end;
%else %do;
	 proc datasets lib=work nolist;
   delete _tmp_:;
   run;
%end;

%mend;

/*
%debug_macro;
%let var_exist=%Check_VarnamesInDsd(indsd=sashelp.cars,Rgx=.,exist_tag=HasVar);
%put &HasVar;

*/

