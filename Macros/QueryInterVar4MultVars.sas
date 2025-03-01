%macro QueryInterVar4MultVars(
query_dsd=,
chr_var=,/*chr var in numeric notation*/
pos_var=,
ref_var=,
alt_var=,
build=hg38,
dsdout=results4allvars
);

data _null_;
set &query_dsd;
n=_n_;
rc=dosubl('%QueryInterVar(chr='||&chr_var||',pos='||&pos_var||
',ref='||&ref_var||',alt='||&alt_var||',build='||"&build"||
',dsdout=_results_'||left(put(n,$8.))||');'
);
run;

*This code section leads to truncated strings when a column var has different string lengths among different data sets subjected to combination;
/* data &dsdout; */
/* set _result_:; */
/* run; */
%Union_Data_In_Lib_Rgx(lib=work,excluded=&dsdout,dsd_contain_rgx=_results_\d+,dsdout=&dsdout);
data &dsdout;set &dsdout;drop dsd;
proc datasets nolist;
delete _results_:;
run;

%mend;

/*Demo codes:;

data a;
input chr pos ref $ alt $;
cards;
22 20994710 C T
9 128940423 T C
;
run;

option mprint mlogic symbolgen;
%QueryInterVar4MultVars(
query_dsd=a,
chr_var=chr,
pos_var=pos,
ref_var=ref,
alt_var=alt,
build=hg38,
dsdout=results4allvars
);
proc print;
run;

*/






