%macro startxl;
filename sas2xl dde 'excel|system';
data _null_;
file sas2xl;
run;

options noxwait noxsync;
%if &syserr ne 0 %then %do;
x '"C:\Program Files (x86)\Microsoft Office\Office12\excel.exe"';
data _null_;
x=sleep(2);
run;
%end;
%mend startxl;
/*
%startxl;
*/
