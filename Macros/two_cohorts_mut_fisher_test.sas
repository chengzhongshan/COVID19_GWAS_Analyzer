
%macro two_cohorts_mut_fisher_test(
dsdin=muts,
chr_var=chr,
pos_var=hg38_pos,
gene_var=gene,/*gene var to aggregate muts for fisher exact test*/
cohort_var=cohort,
cohort1_str=NTU,/*String for cohort1, and other cohorts will be treated as the 2nd cohort for comparison*/
cohort1_tot=,/*Total samples for cohort1*/
cohort2_tot=,/*Total samples for cohort2*/
fig_height=800,/*Figure height*/
fig_width=300,/*Figure width*/
fishersexact_out=fishersexact_bon,/*Fisher exact test with bon adjustment*/
mutfrq_out=mutfrq /*mut frq output*/
);

proc sort data=&dsdin;
by &chr_var &pos_var;
run;
*check recurrent vars;
/* proc sort data=muts dupout=dups nodupkeys;by chr hg38_pos; */
/* run; */
proc sort data=&dsdin;by &gene_var &cohort_var;
proc freq data=&dsdin noprint;
table &gene_var*&cohort_var/fisher list out=&mutfrq_out;
run;
data &mutfrq_out;
set &mutfrq_out;
if cohort="&cohort1_str" then do;
   unaff=&cohort1_tot-count;
end;
else do;
   unaff=&cohort2_tot-count;
end;
run;
proc sort data=&mutfrq_out;
by &gene_var &cohort_var;
proc transpose data=&mutfrq_out 
out=&mutfrq_out._tr(keep=&gene_var &cohort_var _name_ col1 rename=(_name_=pheno col1=num));
var count unaff;
by &gene_var &cohort_var;
run;
data &mutfrq_out._tr;
set &mutfrq_out._tr;
if pheno="COUNT" then pheno="aff";
run;

proc sql;
create table combTb as
select a.*,b.*,c.*,0 as num
from (select distinct &gene_var from &mutfrq_out._tr) as a,
     (select distinct &cohort_var from &mutfrq_out._tr) as b,
     (select distinct pheno from &mutfrq_out._tr) as c
;
proc sql;
create table &mutfrq_out.1 as
select a.&gene_var,a.&cohort_var,a.pheno,a.num,b.num as _num_
from combTB as a
left join
&mutfrq_out._tr as b
on a.&gene_var=b.&gene_var and a.&cohort_var=b.&cohort_var and a.pheno=b.pheno;
data &mutfrq_out.1;
set &mutfrq_out.1;
if _num_>0 then num=_num_;
num=num+1;
run;

proc sort data=&mutfrq_out.1;by &gene_var;
ods select none;
ods output FishersExact=FishersExact;
proc freq data=&mutfrq_out.1;
table pheno*&cohort_var/fisher;
weight num;
by &gene_var;
run;
ods select all;
/* proc print data=fishersexact; */
/* where Name1="P_TABLE"; */
/* run; */
data fishersexact;
set fishersexact;
raw_p=nvalue1;
where Name1="P_TABLE";
run;
proc multtest inpvalues=fishersexact bon out=fishersexact_bon noprint;
id &gene_var;
run;

/*
ods html image_dpi=300 file="NTU_vs_panALL.html" path="%sysfunc(pathname(HOME))";
ods graphics on/reset=all height=200 width=800 noborder;
proc sgplot data=&mutfrq_out;
heatmap x=gene y=cohort /freq=count;
xaxis valueattrs=(family=italic weight=normal size=10);
yaxis valueattrs=(family=normal weight=normal size=10);
run;
*/

proc sort data=&mutfrq_out;
by &cohort_var count;
data &mutfrq_out;
set &mutfrq_out;
ord=_n_;
run;
proc sort data=&mutfrq_out out=gene_ord(keep=&gene_var ord);
by &gene_var ord;
run;
proc sort data=gene_ord nodupkey;
by &gene_var;
proc sort data=gene_ord out=gene_ord;
by ord;
run;


*Need to generate continuous number for making numeric format;
data gene_ord;
set gene_ord;
ord=_n_;
run;
%fmt_num_with_char(
dsdin=gene_ord,
numvar4fmt=ord,
charvar4fmt=&gene_var,
fmt_output_name=num2gene
);
/*This does not work;
%fmt_char_with_num(
dsdin=gene_ord,
var4fmt=gene,
var4sort=ord,
fmt_output_name=ngrp,
varname4fmtvar=xxx,
dsdout=out);
*/

*Need to sort it by the numeric order var ord;
*In the proc sgplot, the yaxis should be sorted by discreteorder=data;
*Note: it is necessary to drop ord var from &mutfrq_out, as the other data set gene_ord contains ord;
*and it is the latter will be used for sorting purpose;

proc sql;
create table &mutfrq_out as
select a.*,b.ord
from &mutfrq_out(drop=ord) as a 
left join
gene_ord as b 
on a.&gene_var=b.&gene_var
order by b.ord, a.&cohort_var;
*It is very important to sort the data by ord and cohort_var;
*Because in the sgplot procedure, SAS will automatically resort the data by ord and cohort_var;
*The discreteorder=data is highly relied on the above, otherwise, the heatmap may have different order of rowlabels;
*Hint: discreteorder by data is required to have the data presorted by specific variable, if there are duplicates;
*for the same ord value, it will be affected by the x variable order, so it is important to sort the data; 
*by ord and x var, cohort_var;
/* proc sql; */
/* select distinct ord,&gene_var from &mutfrq_out; */

ods html image_dpi=300 file="NTU_vs_panALL1.html" path="%sysfunc(pathname(HOME))";
ods graphics on/reset=all height=&fig_height width=&fig_width noborder;
proc sgplot data=&mutfrq_out;
heatmap y=ord x=&cohort_var /freq=count colormodel=(lightblue lightgreen lightred) discretey;
yaxis type=discrete valueattrs=(style=italic weight=normal size=8) discreteorder=data;
xaxis valueattrs=(style=normal weight=normal size=8);
gradlegend / position=top;
*Need to format the order var using its corresponding gene names;
format ord num2gene.;
run;

*This failed for making ordered heatmap;
/*
%mkfmt4grpsindsd(
targetdsd=&mutfrq_out,
grpvarintarget=gene,
name4newfmtvar=new_gene,
fmtdsd=gene_ord,
grpvarinfmtdsd=gene,
byvarinfmtdsd=ord,
finaloutdsd=x1
);


ods html image_dpi=300 file="NTU_vs_panALL1.html" path="%sysfunc(pathname(HOME))";
ods graphics on/reset=all height=800 width=300 noborder;
proc sgplot data=x1;
heatmap y=new_gene x=cohort /freq=count colormodel=(lightblue lightgreen lightred) discretey;
yaxis type=discrete valueattrs=(style=italic weight=normal size=8) discreteorder=unformatted;
xaxis valueattrs=(style=normal weight=normal size=8);
gradlegend / position=top;
run;
*/


/* proc print data=fishersexact_bon(obs=10); */
/* run; */
data fishersexact_bon;
set fishersexact_bon;
Raw=-log10(raw_p);
Adj=-log10(bon_p);
array T{2} Raw Adj;
do i=1 to 2;
  v=T{i};
  grp=vname(T{i});
  output;
end;
run;
*Need to sort it by the numeric order var ord;
*In the proc sgplot, the yaxis should be sorted by discreteorder=data;
proc sql;
create table fishersexact_bon as
select a.*,b.ord
from fishersexact_bon as a 
left join
gene_ord as b 
on a.&gene_var=b.&gene_var
order by b.ord;

ods html image_dpi=300 file="NTU_vs_panALL2.html" path="%sysfunc(pathname(HOME))";
ods graphics on /reset=all height=&fig_height width=&fig_width noborder;
proc sgplot data=fishersexact_bon;
heatmapparm y=ord x=grp colorresponse=v /discretey;
yaxis valueattrs=(style=italic size=8) type=discrete discreteorder=data;
gradlegend /position=top;
format ord num2gene.;
run;

data &fishersexact_out;
set fishersexact_bon;
run;

%mend;

/*Demo codes:;

proc import datafile="%sysfunc(pathname(HOME))/NTU_vs_panALL.txt" dbms=tab out=muts replace;
getnames=yes;guessingrows=max;
run;

filename M url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
%include M;
Filename M clear;
%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0);  

%two_cohorts_mut_fisher_test(
dsdin=muts,
chr_var=chr,
pos_var=hg38_pos,
gene_var=gene,
cohort_var=cohort,
cohort1_str=NTU,
cohort1_tot=502,
cohort2_tot=1098,
fig_height=800,
fig_width=300,
fishersexact_out=fishersexact_bon,
mutfrq_out=mutfrq
);

*/


