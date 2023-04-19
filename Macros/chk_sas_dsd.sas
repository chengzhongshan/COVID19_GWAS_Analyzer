
%macro chk_sas_dsd(lib=work,dsdname=_last_);
%if %sysfunc(exist(&lib..&dsdname)) 
%then %do;
1
%end;
%else %do;
0
%end;
%mend;

/*Demo:
options mprint mlogic symbolgen;

data x;
input y ;
cards;
10
;
run;

%let chk=%chk_sas_dsd;
%put &chk;

libname sc "/home/cheng.zhong.shan/data";
%let chk=%chk_sas_dsd(lib=sc,dsdname=exp);
%put &chk;
*/

