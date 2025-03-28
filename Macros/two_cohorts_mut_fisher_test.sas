%macro two_cohorts_mut_fisher_test(
dsdin=muts,/*Long format dsd only containing positve cases of target genes
Do not supply a long format dsd include all targeted controls and cases at the same time, 
as the macro will count the occurrence of each gene in the input dsd and 
determine the number of controls by sustracting the derived case number
from the supplied total number of samples in the two cohorts, including cohort 1 or 2
Note: fisher test is time consuming when there are very few cases in the input dsd!*/
/*the following macro vars are not needed*/
/*chr_var=chr,*/
/*pos_var=hg38_pos,*/
gene_var=gene,/*gene var to aggregate muts for fisher exact test*/
keepgenewithhigherfrqincohort1=0,/*
Give value 1 to only focus on these muts showing higher
frequency, i.e., risk gene compared to the group Others, from cohort1;
In this way, muts that are risk gene and enriched in the group Others will be excluded; 
This makes sense when the group Others are a mixture and the risk gene is of interested
in the first group, i.e., cohort1.
Note: when the purpose is to analyze all muts different between two cohorts, 
please set the macro variable with value 0!*/
cohort_var=cohort,
cohort1_str=,/*String for cohort1, and other cohorts will be treated as the 2nd cohort for comparison
Note: it is possible to use any variable as target cohort for comparison, as the macro would keep a 
new copy of the input dsd and assign all records not matched with the cohort1_str as Others!*/
use_rgx4cohort1_str=1,/*use perl regular expression to match the cohort1_str*/
cohort1_tot=,/*Total samples for cohort1 matched by using the cohort1_st;
In case of cohort1_str specifically representing a group, the total number of
target group in a cohort that is needed to be calcuated before running the macro;
*/
cohort2_tot=,/*Total samples for cohort2, i.e., all records not matched with cohort1_str;
The same tricky situation as that of cohort1_tot in the cases of cohort1_str specifically
representing a group, it is necessary to get the total number of these Others in a 
cohort that should contain all these records included in the input dsd*/
dsd4cnt_two_cohorts_tot=,/*To save the time and avoid of errors,
it is possible to provide a dataset to calcuate the total number of two groups,
including the case group matched with the cohort1_str and Others that do not
match with the cohort1_str1*/
dsd4subgrp_var=,/*a variable for matching with cohort1_str in the above dsd4cnt_two_cohorts_tot,
which is intended to determine how many samples for the two groups, including the target group and Others
based on the matching of the variable with the cohort1_str!*/
dsd4cnt_sampleid_var=,/*a variable for sample id in the above dsd4cnt_two_cohorts,
which would be used along with dsd4subgrp_var to only keep unique records of two groups, including the target group
matched with the cohort1_str and Others that not matched with the regular expression*/
fig_height=800,/*Figure height*/
fig_width=300,/*Figure width*/
fishersexact_out=Assoc,/*Fisher exact test with bon adjustment*/
mutfrq_out=mutfrq /*mut frq output*/
);

/*The use of chr and pos for removal of duplicate muts*/
/*proc sort data=&dsdin;*/
/*by &chr_var &pos_var;*/
/*run;*/
*check recurrent vars;
/* proc sort data=muts dupout=dups nodupkeys;by chr hg38_pos; */
/* run; */

%if &use_rgx4cohort1_str=0 %then %do;
   %let cohort_matching_condition=%str(&cohort_var="&cohort1_str");
%end;
%else %do;
   %let cohort_matching_condition=%str(prxmatch("/&cohort1_str/i", &cohort_var));
%end;
%put The cohort matching condition: &cohort_matching_condition;

 %if %length(&dsd4cnt_two_cohorts_tot)>0 and %length(&cohort1_tot)=0 and %length(&cohort2_tot)=0 %then %do;

   %if &use_rgx4cohort1_str=0 %then %do;
        %let cohort_matching_condition1=%str(&dsd4subgrp_var="&cohort1_str");
    %end;
    %else %do;
        %let cohort_matching_condition1=%str(prxmatch("/&cohort1_str/i", &dsd4subgrp_var));
     %end;
      data clininfo1;
      set &dsd4cnt_two_cohorts_tot;
      if NOT (&cohort_matching_condition1)  then &dsd4subgrp_var="Others";
      run;
      proc sort data=clininfo1 nodupkeys out=clininfo1;
      by &dsd4cnt_sampleid_var  &dsd4subgrp_var;
      run;
      proc freq data=clininfo1 noprint;
      table &dsd4subgrp_var/list out=clininfo_sum;
      run;
	  data _null_;
	  set clininfo_sum;
	  if trim(left(&dsd4subgrp_var))="Others" then call symputx('cohort2_tot1',put(COUNT,best12.),'G');
	  else call symputx('cohort1_tot1',put(COUNT,best12.),'G');
	  run;
       %if (not %symexist(cohort1_tot1) ) or (not %symexist(cohort2_tot1)) %then %do;
      
         %put Either the macro variables cohort1_tot1 (value=&cohort1_tot1) or cohort2_tot1 (value=&cohort2_tot1) has missing value;
         %put The macro will stop running and exit without aborting other processes outside of the macro;
         %return;
         
      %end;
      
      %put We calculate the total number of samples for the target group (n=&cohort1_tot1) and Others (n=&cohort2_tot1) based on the input data set &dsd4cnt_two_cohorts_tot;
	  %let cohort1_tot=&cohort1_tot1;
	  %let cohort2_tot=&cohort2_tot1;
%end;
%else %do;
	  %put We will use user provided total number of samples for the target group (n=&cohort1_tot) and Others (n=&cohort2_tot);
%end; 

data dsdin;
set &dsdin;
if NOT (&cohort_matching_condition) then &cohort_var="Others";
run;
/*%abort 255;*/
*Also combine all non-Others group as a single group;
proc sql noprint;
select distinct &cohort_var into: case_grp separated by '|'
from dsdin
where &cohort_var ne "Others";
data dsdin;
set dsdin;
if &cohort_var ne "Others" then &cohort_var="&case_grp";
run;

proc sort data=dsdin;by &gene_var &cohort_var;
*Do not use fisher instead apply chisq here;
*as fisher would take forever to calculate the freq;
*Actually, there is no need to calculate chisq here;
proc freq data=dsdin noprint;
*Remove the output var PERCENT, which is not the right one based on the total samples in each grp, such as cases and controls groups;
table &gene_var*&cohort_var/ list out=&mutfrq_out(drop=Percent) ;
run;

data &mutfrq_out;
length type $8.;
set &mutfrq_out;
if &cohort_matching_condition then do;
   type="case";
   grptotal=&cohort1_tot;
   unaff=&cohort1_tot-count;
end;
else do;
   type="control";
   grptotal=&cohort2_tot;
   unaff=&cohort2_tot-count;
end;
run;
/*%abort 255;*/
*Need to further fill these missing group for the variable type when some case or control do not have count;
proc sql;
create table &mutfrq_out._ as
select *
from (select distinct a.&gene_var,b.&cohort_var
         from &mutfrq_out as a,
                  &mutfrq_out as b)
natural left outer join
&mutfrq_out
order by &gene_var,&cohort_var;
*Now rerun previous process;
data &mutfrq_out;
length type $8.;
set &mutfrq_out._;
if count=. then count=0;
if &cohort_matching_condition then do;
   type="case";
   grptotal=&cohort1_tot;
   unaff=&cohort1_tot-count;
end;
else do;
   type="control";
   grptotal=&cohort2_tot;
   unaff=&cohort2_tot-count;
end;
*reasign missing for count=0;
if count=0 then count=.;
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

 /*Now only focus on these muts displaying higher frequency in the first group, i.e., cohort1;*/
/*%if &keepgenewithhigherfrqincohort1=1 %then %do;*/
  proc sql;
  create table chk_&mutfrq_out as
  select a.*,a.count*100/a.grptotal as grpfrq
  from &mutfrq_out as a,
  (select distinct &gene_var from &mutfrq_out where &cohort_var^="Others") as b
  where a.&gene_var=b.&gene_var
  group by a.&gene_var
  order by a.&gene_var,a.&cohort_var;

  data cases_frq ctrs_frq;
  set chk_&mutfrq_out;
  if &cohort_var="Others" then output ctrs_frq;
  else output cases_frq;
  run;

  data case_ctr_frq (where=(case_frq > ctr_frq));
/*  data case_ctr_frq ;*/
  merge cases_frq (keep=&gene_var grpfrq rename=(grpfrq=case_frq)) 
        ctrs_frq (keep=&gene_var grpfrq rename=(grpfrq=ctr_frq));
  by &gene_var;
  run;

  %if %totobsindsd(work.case_ctr_frq)=0 %then %do;
	 %put No muts showing higher frq in the first cohort1;
/*			 %abort 255;*/
	  %return;
	proc sql;
    create table all_tested_genes as
    select distinct a.&gene_var, 0 as HigherFrqInCase
  %end;

/*  %else %do;*/
  *Keep a copy of these genes that do not have muts in the first case group;
/*  proc sql;*/
/*  create table all_tested_genes as*/
/*  select distinct a.&gene_var, */
/*           case when b.case_frq=. then 0*/
/*           else 1*/
/*           end as HigherFrqInCase*/
/*  from dsdin(keep=&gene_var) as a*/
/*  left join*/
/*  (select distinct &gene_var, case_frq  from case_ctr_frq (keep=&gene_var case_frq)) as b*/
/*  on a.&gene_var=b.&gene_var;*/
/*  %end;*/
/*%end;*/

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

/*
data &mutfrq_out.1;
set &mutfrq_out.1;
if _num_>0 then num=_num_;
num=num+1;
run;
*/
*The above will add 1 for all counts;
*To add value 1 only to these groups with missing values;
*It is still needed although we manually assigned 0 for the missing count at lines 135-161;
%AddMissingTag4Grps(
dsdin=&mutfrq_out.1,
grp_vars=&gene_var, 
value_var=_num_,	
varname4missingtag=missingtag,
dsdout=&mutfrq_out.2
);
/*%abort 255;*/
data &mutfrq_out.1;
set &mutfrq_out.2;
num=_num_;
if missingtag=1 then num=ifc(num=.,0,num)+1;
run;

*The sorting by &cohort_var impacts the direction of OR calcuated by proc freq;
/*proc sort data=&mutfrq_out.1;by &gene_var &cohort_var pheno;*/
*Note: use the type (case and control) but not &cohort_var to fix the order of two groups;
*For different cohort_var, the order between &cohort_var and Others will not fixed;
data &mutfrq_out.1;set &mutfrq_out.1;if  &cohort_var="Others" then type="control";else type="case";
run;
*Need to sort both two categories involved in the table statement to fix the OR direction;
proc sort data=&mutfrq_out.1;by &gene_var descending type descending pheno;

/*ods trace on;*/
/*proc freq data=&mutfrq_out.1;*/
/*table pheno*&cohort_var/fisher;*/
/*weight num;*/
/*by &gene_var;*/
/*run;*/
/*ods trace off;*/

ods select none;
ods output FishersExact=FishersExact
                   CrossTabFreqs=CrossTabFreqs
                   Measures=Measures
                   RelativeRisks=RelativeRisks;
/*ods output ChiSq=FishersExact;*/
proc freq data=&mutfrq_out.1 order=data;
*Note: the use of &cohort_var still relies on the type and pheno orders;
table &cohort_var*pheno/fisher exact measures relrisk OR;
/*table pheno*&cohort_var/chisq;*/
weight num;
by &gene_var;
run;
ods select all;

data RelativeRisks(drop=Table StudyType Statistic);
set RelativeRisks;
where statistic="Odds Ratio";
rename value=OR;
run;

*Note: nValue1 and cValue1 are actually the same for the Assoc P in the output by fisher test;
*They are used to represent difference variables included in the Name1 column;
data FishersExact0(drop=Table Name1 Label1 cValue1 nValue1);
set FishersExact;
where Name1="XP2_FISH";
*Here it is problmatic using cValue1 when encountered the assoc P < 0.0001 ;
*Use nValue1 is fine;
P=nValue1+0;
run;

data &mutfrq_out.1(keep=&gene_var col_id count);
length col_id $50.;
set &mutfrq_out.1;
*Make a uniformed label for these cases;
if &cohort_var^="Others" then &cohort_var="Cases";
col_id=catx("_",trim(left(&cohort_var)),trim(left(pheno)));
rename _num_=count;
run; 

proc sort data=&mutfrq_out.1;
by &gene_var col_id;
proc transpose data=&mutfrq_out.1 out=&mutfrq_out._trans(drop=_NAME_);
var count;
by &gene_var;
id col_id;
run;

/*
proc print data=&fisher_dsdout;
where nValue1<1e-3;
run;

%let outcsvname=&cohort1_str._vs_Others;
%ds2csv(data=CrossTabFreqs,csvfile="&outcsvname._crossfrqtb.csv",runmode=b);
%ds2csv(data=Measures,csvfile="&outcsvname._measures.csv",runmode=b);
%ds2csv(data=FishersExact0,csvfile="&outcsvname._fisher.csv",runmode=b);
%ds2csv(data=RelativeRisks,csvfile="&outcsvname._OR.csv",runmode=b);

*/

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
select a.*,b.ord, "&case_grp" as table
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
 %let html_out=%sysfunc(prxchange(s/\\b//,-1,&Cohort1_str));
ods html image_dpi=300 file="&html_out._vs_Others_Frq.html";
*path="%sysfunc(pathname(HOME))";
ods graphics on/reset=all height=&fig_height width=&fig_width noborder imagename="&html_out._vs_Others_cnt";
proc sgplot data=&mutfrq_out;
heatmap y=ord x=&cohort_var /freq=count colormodel=(lightblue lightgreen lightred) discretey;
yaxis type=discrete valueattrs=(style=italic weight=normal size=8) discreteorder=data;
xaxis valueattrs=(style=normal weight=normal size=8);
gradlegend / position=top;
*Need to format the order var using its corresponding gene names;
format ord num2gene.;
run;
/*%abort 255;*/

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

data &fishersexact_out;
set fishersexact_bon;
table="&case_grp";
run;

*Add the var indiciating whether the gene showing higher frq in the case grp;
proc sql;
create table &fishersexact_out as 
select *, case when b.case_frq>0 then 1
               else 0
			   end as HigherFrqInCases
from &fishersexact_out as a
left join
case_ctr_frq as b
on a.&gene_var=b.&gene_var;
%if &keepgenewithhigherfrqincohort1=1 %then %do;
   data  &fishersexact_out;
   set  &fishersexact_out;
   *Assign missing p values for these genes with lower frq in the case group;
   if HigherFrqInCases=0 then do;
      raw=.;adj=.;v=.;
   end;
   run;
%end;

ods html image_dpi=300 file="&html_outr._vs_Others.html";
*path="%sysfunc(pathname(HOME))";
ods graphics on / height=&fig_height width=&fig_width noborder imagename="&html_out._vs_Others";
proc sgplot data=&fishersexact_out;
heatmapparm y=ord x=grp colorresponse=v /discretey NOMISSINGCOLOR;
yaxis valueattrs=(style=italic size=8) type=discrete discreteorder=data;
gradlegend /position=top;
format ord num2gene.;
run;

proc datasets nolist;
delete clininfo1 dsdin clininfo_sum dsdin Fishersexact Chk_: cases_frq Case_ctr_frq ;
run;

*This is the final concise summary for the fisher exact, OR, sample counts;
data &fishersexact_out._;
set &fishersexact_out (where=(grp="Adj"));
keep &gene_var HigherFrqInCases table ;
run;

proc sql;
create table &fishersexact_out as
select *
from &fishersexact_out._
natural left outer join
(
select *
from  &mutfrq_out._trans
natural left outer join
(select *
from FishersExact0
natural left outer join
RelativeRisks)
);

proc datasets nolist;
delete &fishersexact_out._ FishersExact0 
RelativeRisks Measures CrossTabFreqs 
&mutfrq_out._trans gene_or ;
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

************Demo1: Simple usage with user supplied cohort1_tot and cohort2_tot;
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

************Demo2: More sophisticated usage with a data set that contain total number of individuals from cohort1 and cohort2;
 proc import datafile="E:\NTU_Testing/NTU_plus_panALL_pathgenic_vars4fisher_test_with_SAS.txt" dbms=tab 
out=muts replace;
getnames=yes;guessingrows=max;
run;

proc import datafile="E:\NTU_Testing/NTU_plus_panALL_sample_age_sex_subtypes.txt" dbms=tab 
out=clininfo replace;
getnames=yes;guessingrows=max;
run;

%two_cohorts_mut_fisher_test(
dsdin=muts,
gene_var=gene,
keepgenewithhigherfrqincohort1=1,
cohort_var=subtype,
cohort1_str=LowHypo,
cohort1_tot=,
cohort2_tot=,
dsd4cnt_two_cohorts_tot=clininfo,
dsd4subgrp_var=Primary_sample_subtype,
dsd4cnt_sampleid_var=ID,
fig_height=800,
fig_width=300,
fishersexact_out=fishersexact_bon,
mutfrq_out=mutfrq
);

***********Demo3: Test all subtypes using a macro******************;
proc import datafile="E:\NTU_Testing/NTU_plus_panALL_pathgenic_vars4fisher_test_with_SAS.txt" dbms=tab 
out=muts replace;
getnames=yes;guessingrows=max;
run;

proc import datafile="E:\NTU_Testing/NTU_plus_panALL_sample_age_sex_subtypes.txt" dbms=tab 
out=clininfo replace;
getnames=yes;guessingrows=max;
run;

%let cohort_rgx=NTU;
%let cohort_rgx=.;
%let cohort_rgx=panALL;
data muts;set muts;if prxmatch("/&cohort_rgx/i",cohort);
data clininfo;set clininfo;if prxmatch("/&cohort_rgx/i",cohort);
run;
*Now include this into the macro two_cohorts_mut_fisher_test;
data muts;
set muts;
subtype=prxchange("s/\W+/_/",-1,trim(left(subtype)));
run;
proc freq data=muts noprint;
table subtype / list out=mut_subtype_cnt;
run;
proc sql;
select catx('',trim(left(subtype)),'\b') into: tgt_subtypes separated by ' '
from mut_subtype_cnt
where count >1;

*%debug_macro;

%macro TEST_ALL;
%let stypes=&tgt_subtypes separated;
%do i=1 %to %ntokens(&stypes);
%let stype=%scan(&stypes,&i,%str( ));
%let outtag=%sysfunc(prxchange(s/\\b//,-1,&stype));
%two_cohorts_mut_fisher_test(
dsdin=muts,
gene_var=gene,
cohort_var=subtype,
keepgenewithhigherfrqincohort1=1,
cohort1_str=&stype,
cohort1_tot=,
cohort2_tot=,
dsd4cnt_two_cohorts_tot=clininfo,
dsd4subgrp_var=Primary_sample_subtype,
dsd4cnt_sampleid_var=ID,
fig_height=800,
fig_width=300,
fishersexact_out=Assoc4&outtag,
mutfrq_out=mutfrq4&outtag 
);
%end;

%mend;

%TEST_ALL;

data all;
set Assoc4:;
*if HigherFrqInCases=1 and P<0.05 and P>0 and Cases_aff>1;
if Cases_aff>=2;
run;
%let cohort_rgx=%sysfunc(ifc("&cohort_rgx"=".",panALL_plus_NTU,&cohort_rgx));
%ds2csv(data=all,csvfile="%sysfunc(pathname(HOME))/fisher_for_&cohort_rgx..csv",runmode=b);


*/


