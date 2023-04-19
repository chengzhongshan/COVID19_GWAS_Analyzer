%macro split_wide_dsd(
dsdin,
dsdout_prefix,
split_num4vars,
dsdout4subdsd,
delete_original_dsd=1);

*Get the total number of vars in a dsd;
data _null_;
dsdid=open("&dsdin",'I');
tot=attrn(dsdid,'nvars');
call symput('totvars',left(put(tot,12.)));
rc=close(dsdid);
run;
%put Total vars in your dsd &dsdin is &totvars;

proc contents data=&dsdin out=var_info (keep=name varnum) noprint;
run;
*Important to sort vars by varnum to keep original order of vars;
*This is pivital for the keep &&V&i -- &&V&end_num;
proc sql noprint;
select name into: V1 - : V&totvars
from var_info
order by varnum;

%do ti=1 %to &totvars %by &split_num4vars;
   data &dsdout_prefix.&ti;
   set &dsdin;
   %let end_num=%eval(&ti+&split_num4vars-1);
   %if %eval(&end_num>&totvars) %then %let end_num=&totvars;
*This may fail;
/*    keep &&V&i -- &&V&end_num; */
    keep %do ki=&ti %to &end_num;
          &&V&ki
          %end;
          ;
   run;
   
   %if "&delete_original_dsd"="1" %then %do;
   *drop these vars from original dsdin to release space;
    data &dsdin;
    set &dsdin;
*This may fail;    
/*     drop &&V&i -- &&V&end_num; */
    drop %do di=&ti %to &end_num;
          &&V&di
          %end;
          ;
    run;
   %end;

*This may not use too much resource compared to the above procedure;
*However, it does not delete these vars;
/*       proc datasets lib=work nolist; */
/*       modify &dsdin; */
/*       drop %do di=&i %to &end_num; */
/*             &&V&di */
/*       %end; */
/*       ; */
/*       run; */
%end;

*Output sub dsd names for later manipulation;
ods select none;
ods output members=members;
proc datasets lib=work memtype=data;
run;
ods select all;
data &dsdout4subdsd;
set members(keep=name);
if prxmatch("/^&dsdout_prefix\d+/i",name);
run;
%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname V8 '/home/cheng.zhong.shan/data';
data exp;
set V8.exp(keep=V1-V1000);
run;

%split_wide_dsd(
dsdin=exp,
dsdout_prefix=SmallSub,
split_num4vars=10,
dsdout4subdsd=subdsdinfo,
delete_original_dsd=1
);


*/
