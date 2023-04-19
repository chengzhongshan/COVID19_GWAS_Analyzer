%macro sc_glm4genes(
/*Note: sc_freq_boxplot also perform DEG analysis, which is better than this macro*/
dsd,
dsd_headers,
dsd_umap,
genes,
GLMStatOutDsd,
GLM_classes=sex medication severity,
GLM_model=severity sex age medication,
samplewide=1,
sample_var=sample,
pheno_var=severity,
where_condition=
);

/* proc print data=sc.exp(obs=10); */
/* var rownames v1-v100; */
/* run; */

%rank4grps(
grps=&genes,
dsdout=tgt_genes
);
data _null_;
set tgt_genes(obs=1);
if prxmatch('/\|/',grps) then tag=1;
else tag=0;
call symputx('gene_tag',tag);
run;
*sc rownames are usually in the format of ensembl|genesymbol;
%if %eval(&gene_tag=1) %then %do;
proc sql noprint;
select quote(scan(grps,2,'|')) into: _genes_ separated by ","
from tgt_genes;
%end;
%else %do;
proc sql noprint;
select quote(grps) into: _genes_ separated by ","
from tgt_genes;
%end;

*This is too slow; 
*Use data step instead;
/* proc sql; */
/* create table tgt as */
/* select a.* */
/* from &dsd as a, */
/*      tgt_genes as b */
/* where a.rownames=b.grps; */

data tgt;
set &dsd;
where rownames in (&_genes_) or scan(rownames,2,'|') in (&_genes_);
run;

*transpose wide data into long format data;
data tgt;
set tgt;
array X{*} _numeric_;
do i=1 to dim(X);
 *Since the var i NOT always contain the required variable order;
 xi=prxchange('s/V//',-1,vname(X{i}))+0;
 exp=X{i};
 output;
end;
drop i V:;
run;
/* proc sgplot data=tgt; */
/* histogram exp; */
/* run; */
/* proc print data=sc.umap(obs=10); */
/* proc print data=sc.headers(obs=10); */
/* proc print data=tgt(obs=10); */
/* run; */
proc sql;
create table tgt as
select a.*,c.*
from tgt as a,
     &dsd_headers as b,
     &dsd_umap as c
where c.seq_id=b.colnames and a.xi=b.i; 
data tgt;
set tgt;
*Add 1 for exp and transform it with log2;
exp=log2(exp+1);
run;

*Use samplewide avg but not median expression for plotting;
*Note: it is necessary to include 0 values when calculating samplewide avg exp;
%if &samplewide and &sample_var ne %then %do;
%let GLM_model_Vars=%sysfunc(prxchange(%str(s/ /,/),-1,&GLM_model));
 proc sql;
 create table tgt as
 select &GLM_model_Vars, rownames, Cluster,
 &sample_var, avg(exp) as exp
/*  from tgt (where=(exp>0))  */
 from tgt
 group by &sample_var, rownames, Cluster;
 proc sort data=tgt nodupkeys;by _all_;run;
%end;

proc sort data=tgt;by rownames cluster;
run;
/* ods trace on; */
ods select none;
ods output ModelANOVA=&GLMStatOutDsd DIFF=&GLMStatOutDsd._pdiff;
proc glm data=tgt PLOTS(MAXPOINTS=50000000000);
%if %length("&where_condition")>0 %then %do;
where &where_condition;
%end;
/* class sex medication severity; */
class &GLM_classes;
/* model exp=severity sex age medication/ss3; */
model exp= &GLM_model/ss3;
lsmeans &pheno_var/pdiff=all adjust=tukey; 
by rownames cluster;
run;

/* ods trace off; */
ods select all;
data &GLMStatOutDsd;
set &GLMStatOutDsd;
keep rownames cluster source df ss ms fvale probF;
attrib probF format=best12.;
run;
data &GLMStatOutDsd._pdiff;
set &GLMStatOutDsd._pdiff;
*As sas output numeric variable names for these p values;
*It is impossible to use attrib to change them;
attrib _numeric_ format=best32.;
run;
title "LSMEANs tukey differentiation analysis among different groups";
proc print data=&GLMStatOutDsd._pdiff;
%print_nicer;
run;

%mend;

/*Demo code:

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname sc "/home/cheng.zhong.shan/data";

*options mprint mlogic symbolgen;
%let glist=MAP3K19 R3HDM1 CXCR4 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163;
%sc_glm4genes(
dsd=sc.exp,
dsd_headers=sc.headers,
dsd_umap=sc.umap,
genes=&glist,
GLMStatOutDsd=GLMStatOut,
GLM_classes=sex medication severity,
GLM_model=severity sex age medication,
samplewide=1,
sample_var=sample,
pheno_var=severity,
where_condition=
);

*Make heatmap;
data dsd4heatmap (keep=rownames cluster logP);
set GLMStatOut;
logP=-log10(probF);
*if logP<-log10(0.05/(12*21)) then logp=.;
if logP<1.3 then logp=.;
if logP>50 then logP=50;
where source="severity" and 
      Cluster not contains 'Outlier';
label Cluster="Single cell types" rownames="Genes close rs16831827"
logP="ANOVA -log10(P) among healthy control, severe, and critical COVID-19";      
run;

%heatmap4longformatdsd(
dsdin=dsd4heatmap,
xvar=rownames,
yvar=Cluster,
colorvar=logP,
fig_height=800,
fig_width=800,
outline_thickness=2,
where_condition=
);

*/


