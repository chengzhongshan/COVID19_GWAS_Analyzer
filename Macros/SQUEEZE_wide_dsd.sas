%macro SQUEEZE_wide_dsd(
dsdin,
dsdout_prefix,
split_num4vars,
dsdout
);
*Split large wide dsd;
%split_wide_dsd(
dsdin=&dsdin,
dsdout_prefix=&dsdout_prefix,
split_num4vars=&split_num4vars,
dsdout4subdsd=subdsdinfo,
delete_original_dsd=1
);

*Get the total number of vars in the subdsdinfo;
data _null_;
set subdsdinfo end=eof;
if eof then do;
 call symput('nds',left(put(_n_,12.)));
end;
run;
%put Total vars in your dsd subdsdinfo is &nds;

proc sql noprint;
select name into: D1 - : D&nds
from subdsdinfo;

%do si=1 %to &nds;
    %SQUEEZE(dsnin=&&D&si,dsnout=_Squeezed&si);
    proc datasets lib=work nolist;
    delete &&D&si;
    run;
%end;
*This will dramatically reduce dataset size!;
options compress=yes;
data &dsdout;
%do i=1 %to &nds;
 set _Squeezed&i;
%end;
run;
options compress=no;

proc datasets nolist;
delete _Squeezed:;
run;

*Output sub dsd names for later manipulation;
/* ods select none; */
/* ods output members=members; */
/* proc datasets lib=work memtype=data; */
/* run; */
/* ods select all; */
/* data &dsdout4subdsd; */
/* set members(keep=name); */
/* if prxmatch("/^&dsdout_prefix\d+/i",name); */
/* run; */

%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname V8 '/home/cheng.zhong.shan/data';
data exp;
set V8.exp(keep=V1-V1000);
run;

%SQUEEZE_wide_dsd(
dsdin=exp,
dsdout_prefix=SmallSub,
split_num4vars=100,
dsdout=final_combined
);
proc datasets lib=work;
run;


*/
