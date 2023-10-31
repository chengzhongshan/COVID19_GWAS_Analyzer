%macro sc_freq_boxplot(
/*Note: the macro also perform gene expression differential expression analysis!;*/
longformdsd,
cell_type_var= ,/*It will be used for lattice boxplot headernames*/
sample_grp_var= ,/*This will be used to generate sample level cell expression statistics*/ 
pheno_var= , /*Pheno var will be used as categories for boxplot*/
cust_pheno_order=, /*User supplied phenos in rank, and the order will be applied to boxplot categories*/
exp_var= ,
exp_cutoff=0,
boxplot_height=300,
boxplot_width=800,
boxplot_nrows=4,
where_cnd_for_sgplot=%quote( ),
frqout=frqout,
other_glm_classes=,
aggre_sc_glm_pdiff_dsd=all_sc, /*provide a prefix to name the results generated by performing
 glm lsmean by single cell type for gene exp across different cell types*/

/*Perform sample level exp analysis: 
-1: no single cell level and sample level; 
1: yes for sample leve only; 0: yes only for single cell level
2: both at single cell and sample level;
Note: median will be used to calculate sample leve expression;
*/
sample_level_exp_analysis=2

);

*Keep a copy of pheno_var for proc glm with longformdsd;
%let _pheno_var=&pheno_var;

/* proc print data=&longformdsd (obs=10);run; */
proc sort data=&longformdsd out=tgt_samples nodupkeys;
by &sample_grp_var;
run;

data &longformdsd;
set &longformdsd;
expressed=0;
if &exp_var>&exp_cutoff then expressed=1;
run;
/* proc freq data=&longformdsd; */
/* table expressed; */
/* run; */
/* %abort 255; */
proc sort data=&longformdsd;by &sample_grp_var;

proc datasets lib=work nolist;
delete &frqout;
run;
proc freq data=&longformdsd 
%if %length(&where_cnd_for_sgplot) >0 %then %do;
(where=(%unquote(&where_cnd_for_sgplot)))
%end;
;
table expressed*&cell_type_var/out=&frqout sparse noprint;
by &sample_grp_var;
run;
/* %abort 255; */

data &frqout;
set &frqout;
where expressed=1;
run;

proc sort data=&longformdsd (keep=&sample_grp_var &pheno_var &other_glm_classes) out=samples nodupkeys;
by &sample_grp_var &pheno_var &other_glm_classes;
run;
proc sql;
create table &frqout as
select a.*,b.&pheno_var
%if %length(&other_glm_classes) > 0 %then %do;
  ,%qsysfunc(prxchange(s/ /%str(,)/,-1,&other_glm_classes))
%end; 
from &frqout as a
left join
samples as b
on a.&sample_grp_var=b.&sample_grp_var;
/* %abort 255; */

%if %length(&cust_pheno_order)>0 %then %do;
%let ninput=%ntokens(&cust_pheno_order);
proc sql;
select unique(&pheno_var) into: pheno_cats separated by ' '
from &frqout;
select count(unique(&pheno_var)) into: npheno_cats
from &frqout;

%*Check whether the total number of &cust_pheno_order is equal to that of &npheno_cats;
%if %eval(&ninput=&npheno_cats) %then %do;
  %put The total number of categories for your phenotype &pheno_var are the same as the input;
  %put &pheno_var: &pheno_cats;
  %put customized pheno cats: &cust_pheno_order;
%end;
%else %do;
  %put Your input customized categories (&cust_pheno_order) are different from that of the dataset (&pheno_cats);
  %abort;
%end;

%*boxplot categories by customized order;
%rank4grps(
grps=&cust_pheno_order,dsdout=g
);
%mkfmt4grps_by_var(
grpdsd=g,
grp_var=grps,
by_var=num_grps,
outfmt4numgrps=x2y,
outfmt4chargrps=y2x
);
data &frqout;
set &frqout;
*format char grps to numeric grps;
num_pheno_var=input(&pheno_var,x2y.);
run;
data &longformdsd;
set &longformdsd;
*format char grps to numeric grps;
num_pheno_var=input(&pheno_var,x2y.);
run;
%let pheno_var=num_pheno_var;
%end;

*This will generate wrong results;
/* proc sql; */
/* create table tgt_frq as */
/* select sum(expressed)/count(expressed) as frq, */
/*        sample,cluster,severity */
/*        from tgt */
/*        group by sample,cluster; */
/* proc sort nodupkeys;by _all_;run;   */

***************************************************************************;
*Boxplot for cell percent;
title "Cell type percent for SAS data set &longformdsd with &exp_var>&exp_cutoff";
ods graphics on /reset=all height=&boxplot_height width=&boxplot_width noborder;  
proc sgpanel data=&frqout;
%if %length(&where_cnd_for_sgplot) >0 %then %do;
where %unquote(&where_cnd_for_sgplot);;
%end;

%if %length(&cust_pheno_order)>0 %then %do;
format &pheno_var y2x.;
label &pheno_var="Group";
%end;
*Add uniscale=column to enable the y-axis not in uniform;
panelby &cell_type_var/rows=&boxplot_nrows onepanel novarname;
/* vbar frq/group=&cell_type_var groupdisplay=cluster; */
*Add category=&pheno_var will display xaxis for boxplot;
vbox percent /group=&pheno_var groupdisplay=cluster
         boxwidth=0.6
         outlierattrs=(color=black symbol=circle size=4)
         whiskerattrs=(color=black thickness=1 pattern=2) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=black symbol=circlefilled color=darkblue size=8);
keylegend /noborder valueattrs=(size=10);
label percent="Cell percent";
run;
proc sql;
select distinct
       median(percent) as median_pct,
       std(percent) as std_pct,
       &cell_type_var,&pheno_var
from &frqout
group by &cell_type_var,&pheno_var;

title "";

***************************************************************************;
*Boxplot for cell counts;
title "Cell type count for SAS data set &longformdsd with &exp_var>&exp_cutoff";
ods graphics on /reset=all height=&boxplot_height width=&boxplot_width noborder;  
proc sgpanel data=&frqout;
%if %length(&where_cnd_for_sgplot) >0 %then %do;
where %unquote(&where_cnd_for_sgplot);;
%end;

%if %length(&cust_pheno_order)>0 %then %do;
format &pheno_var y2x.;
label &pheno_var="Group";
%end;
*Add uniscale=column to enable the y-axis not in uniform;
panelby &cell_type_var/rows=&boxplot_nrows onepanel novarname uniscale=column;
/* vbar frq/group=&cell_type_var groupdisplay=cluster; */
*Add category=&pheno_var will display xaxis for boxplot;
vbox count /group=&pheno_var groupdisplay=cluster
         boxwidth=0.6 
         outlierattrs=(color=black symbol=circle size=4)
         whiskerattrs=(color=black thickness=1 pattern=2) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=black symbol=circlefilled color=darkblue size=8);
keylegend /noborder valueattrs=(size=10);
label percent="Cell percent";
/* rowaxis type=log logbase=10 logstyle=logexponent; */
rowaxis type=log logbase=10 logstyle=logexpand;
run;
proc sql;
select distinct
       median(percent) as median_pct,
       std(percent) as std_pct,
       &cell_type_var,&pheno_var
from &frqout
group by &cell_type_var,&pheno_var;

title "";


%if %eval(&sample_level_exp_analysis>=1) %then %do;
***************************************************************************;
*Boxplot for cell exp at sample level;

proc sql;
create table _tmp_ as
select distinct
       &cell_type_var, &pheno_var, &_pheno_var,
       median(&exp_var) as &exp_var, &sample_grp_var
       %if %length(&other_glm_classes) > 0 %then %do;
         ,%qsysfunc(prxchange(s/ /%str(,)/,-1,&other_glm_classes))
       %end; 
from &longformdsd
group by &sample_grp_var, &cell_type_var
;

/* %abort 255; */
/* *Need to remove dups; */
/* proc sort data=_tmp_ nodupkeys; by _all_; */
/* run; */

title "Cell type gene expression at sample level for SAS data set &longformdsd with &exp_var>&exp_cutoff";
ods graphics on /reset=all height=&boxplot_height width=&boxplot_width noborder;  
proc sgpanel data=_tmp_;
%if %length(&where_cnd_for_sgplot) >0 %then %do;
where %unquote(&where_cnd_for_sgplot);;
%end;

%if %length(&cust_pheno_order)>0 %then %do;
format &pheno_var y2x.;
label &pheno_var="Group";
%end;
*Add uniscale=column to enable the y-axis not in uniform;
panelby &cell_type_var/rows=&boxplot_nrows onepanel novarname uniscale=column;
/* vbar frq/group=&cell_type_var groupdisplay=cluster; */
*Add category=&pheno_var will display xaxis for boxplot;
vbox &exp_var /group=&pheno_var groupdisplay=cluster
         boxwidth=0.6
         outlierattrs=(color=black symbol=circle size=4)
         whiskerattrs=(color=black thickness=1 pattern=2) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=black symbol=circlefilled color=darkblue size=8);
keylegend /noborder valueattrs=(size=10);
label &exp_var="Log2(normalized expression + 1)";
/* rowaxis type=log logbase=10 logstyle=logexponent; */
/* rowaxis type=log logbase=10 logstyle=logexpand; */
run;
proc sql;
select distinct
       median(&exp_var) as median_exp,
       std(&exp_var) as std_exp,
       &cell_type_var,&pheno_var,&_pheno_var
from _tmp_
group by &cell_type_var,&pheno_var;

title "";


%end;

%if %eval(&sample_level_exp_analysis=0 or &sample_level_exp_analysis=2) %then %do;
***************************************************************************;
*Boxplot for cell exp;
title "Cell type gene expression for SAS data set &longformdsd with &exp_var>&exp_cutoff";
ods graphics on /reset=all height=&boxplot_height width=&boxplot_width noborder;  
proc sgpanel data=&longformdsd;
%if %length(&where_cnd_for_sgplot) >0 %then %do;
where %unquote(&where_cnd_for_sgplot);;
%end;

%if %length(&cust_pheno_order)>0 %then %do;
format &pheno_var y2x.;
label &pheno_var="Group";
%end;
*Add uniscale=column to enable the y-axis not in uniform;
panelby &cell_type_var/rows=&boxplot_nrows onepanel novarname uniscale=column;
/* vbar frq/group=&cell_type_var groupdisplay=cluster; */
*Add category=&pheno_var will display xaxis for boxplot;
vbox &exp_var /group=&pheno_var groupdisplay=cluster
         boxwidth=0.6 
         outlierattrs=(color=black symbol=circle size=4)
         whiskerattrs=(color=black thickness=1 pattern=2) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=black symbol=circlefilled color=darkblue size=8);
keylegend /noborder valueattrs=(size=10);
label &exp_var="Log2(normalized expression + 1)";
/* rowaxis type=log logbase=10 logstyle=logexponent; */
/* rowaxis type=log logbase=10 logstyle=logexpand; */
run;
proc sql;
select distinct
       median(&exp_var) as median_exp,
       std(&exp_var) as std_exp,
       &cell_type_var,&pheno_var
from &longformdsd
group by &cell_type_var,&pheno_var;

title "";

%end;


******************************GLM for cell percent among different groups**********************************;
proc sort data=&frqout;by &cell_type_var;
ods graphics on/reset=all noborder;
/* ods trace on; */
title "Cell type PERCENT GLM analysis &longformdsd with &exp_var>&exp_cutoff";
ods output MANOVA=PCT_MANOVA  Diff=&frqout._pdiff;
proc glm data=&frqout;
class &pheno_var &other_glm_classes;
model percent=&pheno_var &other_glm_classes/ss3;
*change the multiple adjustment parameter adjust as one of [bon tukey and others];
lsmeans &pheno_var / pdiff=all out=&frqout._lsmean_pdiff adjust=tukey;
by &cell_type_var;
run;
/* ods trace off; */

data &frqout._pdiff;
set &frqout._pdiff;
*As sas output numeric variable names for these p values;
*It is impossible to use attrib to change them;
attrib _numeric_ format=best32.;
run;

******************************GLM for cell count among different groups**********************************;
proc sort data=&frqout;by &cell_type_var;
ods graphics on/reset=all noborder;
/* ods trace on; */
title "Cell type COUNT GLM analysis &longformdsd with &exp_var>&exp_cutoff";
ods output MANOVA=CNT_MANOVA  Diff=&frqout._pdiff_cnt;
proc glm data=&frqout;
class &pheno_var &other_glm_classes;
model count=&pheno_var &other_glm_classes/ss3;
*change the multiple adjustment parameter adjust as one of [bon tukey and others];
lsmeans &pheno_var / pdiff=all out=&frqout._lsmean_cnt adjust=tukey;
by &cell_type_var;
run;
/* ods trace off; */

data &frqout._pdiff;
set &frqout._pdiff;
*As sas output numeric variable names for these p values;
*It is impossible to use attrib to change them;
attrib _numeric_ format=best32.;
run;



%if %eval(&sample_level_exp_analysis>=1) %then %do;
******************************GLM for gene exp at sample level of single cells among different groups**********************************;
proc sort data=_tmp_;by &cell_type_var;
ods graphics on/reset=all noborder;
/* ods trace on; */
title "Cell type GENE EXPRESSION at sample level GLM analysis &longformdsd with &exp_var>&exp_cutoff";
ods output MANOVA=&aggre_sc_glm_pdiff_dsd._sample_MANOVA  Diff=&aggre_sc_glm_pdiff_dsd._sample_pdiff;
proc glm data=_tmp_;
class &_pheno_var &other_glm_classes;
model &exp_var=&_pheno_var &other_glm_classes/ss3;
*change the multiple adjustment parameter adjust as one of [bon tukey and others];
lsmeans &_pheno_var / pdiff=all out=lsmean_pdiff adjust=tukey;
by &cell_type_var;
run;
/* ods trace off; */
data &aggre_sc_glm_pdiff_dsd._sample_pdiff;
set &aggre_sc_glm_pdiff_dsd._sample_pdiff;
*As sas output numeric variable names for these p values;
*It is impossible to use attrib to change them;
attrib _numeric_ format=best32.;
run;

%end;

%if %eval(&sample_level_exp_analysis=0 or &sample_level_exp_analysis=2)  %then %do;
******************************GLM for gene exp of single cells among different groups**********************************;
proc sort data=&longformdsd;by &cell_type_var;
ods graphics on/reset=all noborder;
/* ods trace on; */
title "Cell type GENE EXPRESSION GLM analysis &longformdsd with &exp_var>&exp_cutoff";
ods output MANOVA=&aggre_sc_glm_pdiff_dsd._celltype_MANOVA  Diff=&aggre_sc_glm_pdiff_dsd._celltype_pdiff;
proc glm data=&longformdsd;
class &_pheno_var &other_glm_classes;
model &exp_var=&_pheno_var &other_glm_classes/ss3;
*change the multiple adjustment parameter adjust as one of [bon tukey and others];
lsmeans &_pheno_var / pdiff=all out=lsmean_pdiff adjust=tukey;
by &cell_type_var;
run;
/* ods trace off; */
data &aggre_sc_glm_pdiff_dsd._celltype_pdiff;
set &aggre_sc_glm_pdiff_dsd._celltype_pdiff;
*As sas output numeric variable names for these p values;
*It is impossible to use attrib to change them;
attrib _numeric_ format=best32.;
run;

%end;


/* https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.4/statug/statug_npar1way_examples01.htm */
/* proc npar1way data=insect wilcoxon; */
/* class spray; */
/* var bugs; */
/* exact wilcoxon; */
/* run; */

%mend;

/*
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname sc "/home/cheng.zhong.shan/data";

%macro sc_visulization4gene(gene);

%sc_scatter4gene(
dsd=sc.exp,
dsd_headers=sc.headers,
dsd_umap=sc.umap,
gene=&gene,
pheno_var=severity,
pheno_categories=control_healthy severe critical
samplewide=0,
sample_var=,
boxplot_width=300,
boxplot_height=800,
umap_width=1000,
umap_height=400,
umap_lattice_nrows=1,
boxplot_nrows=5,
where_cnd4sgplot=,
rgx2cells_not_matched_as_other=iliated
);
*%quote(cluster contains %'iliated%');
%mend;

%sc_visulization4gene(gene=MAP3K19);

*Use the dataset tgt generated by above to run the macro;
data tgt;
length cell_type $50.;
set tgt;
cell_type="Other";
if prxmatch('/iliated/',Cluster) then cell_type=Cluster;
run;
proc sql;
select unique(cell_type) 
from tgt;

*Get percent of different cells;
*Note: we use the exp_cutoff=-1;
*This will calcuate the percents of different cells within each pheno group;
*percent=cells/total_cells_in_a_pheno_grp;
%sc_freq_boxplot(
longformdsd=tgt,
cell_type_var=cell_type,
sample_grp_var=sample,
pheno_var=severity,
cust_pheno_order=control_healthy severe critical,
exp_var=exp,
exp_cutoff=-1,
boxplot_height=800,
boxplot_width=300,
boxplot_nrows=5,
where_cnd_for_sgplot=%quote( cell_type contains 'iliated' or cell_type='Other'),
frqout=cellfrqout,
other_glm_classes=sex medication,
aggre_sc_glm_pdiff_dsd=all_sc
);


*This will calcuate the percents cells passing the exp threshold among its total number of corresponding cells;
*percent=cells_expressed_gene/total_cells_of_specific_type;
%sc_freq_boxplot(
longformdsd=tgt,
cell_type_var=cell_type,
sample_grp_var=sample,
pheno_var=severity,
cust_pheno_order=control_healthy severe critical,
exp_var=exp,
exp_cutoff=0,
boxplot_height=800,
boxplot_width=300,
boxplot_nrows=5,
where_cnd_for_sgplot=%quote( cell_type contains 'iliated' or cell_type='Other'),
frqout=exp_cellfrqout,
other_glm_classes=sex medication,
aggre_sc_glm_pdiff_dsd=all_sc
);


*/


  

