%macro Boxplots4GenesInGTExV8ByGrps(
genes=MAP3K19 R3HDM1 CXCR4 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163;,
dsdout=exp,
bygrps=sex AA, /*by AA population and sex or either of them!*/
UseGeneratedDsd=0,
PreviousDsd=tgt, /*This is a fixed dsd used by the proc sgpanel*/
Lib4PreviousDsd=GTEx,
WhereFilters4Boxplot=%str(),
boxplot_width=1200,
boxplot_height=1000
);

%if &boxplot_height eq %then 
%let boxplot_height=%eval(250*%ntokens(&genes));
%let gene4sort=%qscan(&genes,1,%str( ));
*if &UseGeneratedDsd=0, will use previous generated dsd;
%if %eval(&UseGeneratedDsd^=1) or 
(%sysfunc(exist(&Lib4PreviousDsd..exp_all)) 
 and 
 (
 %sysfunc(exist(&Lib4PreviousDsd..headers)) or
 %sysfunc(exist(headers))
 )
)
 
%then %do;
%if %sysfunc(exist(headers)) %then %do;
   %put Use headers in work lib;
   %let dsd_headers=headers;
%end;
%else %do;
   %put use headers in the lib &Lib4PreviousDsd;
   %let dsd_headers=&Lib4PreviousDsd..headers;
%end;

%let dsd_umap=umap;

%if %sysfunc(exist(&Lib4PreviousDsd..exp_all)) %then %do;
  %put You have previous whole GTEx dataset: &Lib4PreviousDsd..exp_all;
  %put We will not download the large dataset again;
  
  data exp;
  set &Lib4PreviousDsd..exp_all;
  *Note: rownames are in genesymbol already;
  where rownames in (%quotelst(&genes)) or 
        scan(rownames,2,'|') in (%quotelst(&genes));
  run;
  
  data exp;
  set exp;
  if prxmatch('/[^\|]+\|[^\|]+/',rownames) then 
     rownames=scan(rownames,2,'|');
  run;
  
%end;
%else %do;
*To avoid of I/O failure in SAS due to out of space, run it at the beginning;
*Now download UCSC single cell gene expression data;
%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=https://cells.ucsc.edu/gtex8/exprMatrix.tsv.gz,
dsdout4headers=headers,
dsdout4data=exp_all,
extra_cmd4infile=
);

*Need to save headers for future usage;
data &Lib4PreviousDsd..headers;
set headers;
run;
*extra_cmd4infile=%str(rownames=scan(rownames,2,"|"));
*subset exp by query genes;
/* %let genes=MAP3K19 R3HDM1 CXCR4 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163; */
/* proc print data=exp(obs=10 keep=rownames v1-v10);run; */
*It is necessary to use where function after the exp dataset was created!;

*The squeeze process is included in the macro ucsc_cell_matrix2wideformatdsd;
*Mainly because the two squeeze macros can not handle very long wide dataset;
/* %squeeze( */
/* dsnin=exp, */
/* dsnout=exp_all); */

/* %SQUEEZE_wide_dsd( */
/* dsdin=exp, */
/* dsdout_prefix=SmallSub, */
/* split_num4vars=100, */
/* dsdout=exp_all */
/* ); */


data exp;
set exp_all;
where scan(rownames,2,'|') in (%quotelst(&genes));
run;

data exp;
set exp;
rownames=scan(rownames,2,'|');
run;

%end;

%if (%sysfunc(exist(&Lib4PreviousDsd..umap))) %then %do;
%put Use previously generated UMAP dataset &Lib4PreviousDsd..umap;
data umap;
set &Lib4PreviousDsd..umap;
run;
%end;
%else %do;
*Download UMAP gz file;
%let httpfile_url=https://cells.ucsc.edu/gtex8/UMAP.coords.tsv.gz;
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%dwn_http_file(httpfile_url=&httpfile_url,outfile=Seurat_umap.coords.tsv.gz,outdir=%sysfunc(getoption(work)));

*Import UMAP gz file into SAS;
%ImportFileHeadersFromZIP(
zip=%sysfunc(getoption(work))/Seurat_umap.coords.tsv.gz,
filename_rgx=.,
obs=max,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(
obs=max delimiter='09'x truncover;
input tissue_id :$200. x y;)
);

*Download cell type and other meta info;
*The header is abnormal, just ignor it;
filename meta url 'https://cells.ucsc.edu/gtex8/meta.tsv';
proc import datafile=meta dbms=tab out=info replace;
getnames=no;guessingrows=max;datarow=2;
run;
data info;
set info;
rename var1=tissue_id var9=cluster var13=sample Var8=Tissue;
run;
filename S url "https://storage.googleapis.com/gtex_analysis_v8/annotations/GTEx_Analysis_v8_Annotations_SubjectPhenotypesDS.txt";
proc import datafile=S dbms=tab out=sex_info replace;
getnames=yes;guessingrows=max;
run;
data sex_info(drop=_sex_);
length sex $1.;
set sex_info(rename=(sex=_sex_));
sex='F';
if _sex_=1 then sex='M';
run;

*Add meta info into UMAP dataset;
/*
proc print data=x(obs=10);
proc print data=info(obs=10);
run;
proc contents data=info;
run;
*/

*It is important to remove the trailing '-' as some tissue id less than 10 chars;
proc sql;
create table UMAP as 
select a.*,b.*,c.*
from x as a,
     info as b,
     sex_info as c
where a.tissue_id=b.tissue_id and 
      prxchange('s/-$//',-1,substr(a.tissue_id,1,10)) = c.SUBJID;

/* *Draw scatterplot of UMAP;     */
/* proc sgplot data=UMAP; */
/* scatter x=x y=y/group=cluster; */
/* run; */

proc sql noprint;
select unique(Tissue) into: tgrps separated by " "
from umap;
/* proc print data=umap(obs=10); */
/* run; */
data umap;
set umap;
*seq_id is a default var used by sc_scatter4gene;
rename tissue_id=seq_id;
run;
*Need to save umap for future usage;
data &Lib4PreviousDsd..umap;
set umap;
run;

%end;


/* %let dsd_headers=headers; */
/* %let dsd_umap=umap; */
/* %let gene4sort=%qscan(&genes,1,%str( )); */
/* %let boxplot_width=1200; */
/* %let boxplot_height=%eval(250*%ntokens(&genes)); */
/* %let boxplot_nrows=3; */

/* %let ncats=%ntokens(&pheno_categories); */

/* proc print data=sc.exp(obs=10); */
/* var rownames v1-v100; */
/* run; */
*transpose wide data into long format data;
data tgt;
set exp;
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
label x="UMAP_1" y="UMAP_2"
      exp="log2(normalized expression + 1)";
*remove outlier clusters;
where Cluster not contains 'Outlier';    
run;

*Add AA population info;
*Add AA info;
/* proc import datafile="/home/cheng.zhong.shan/data/GTEx_V8/117AX.txt"  */
/* dbms=tab out=AA_info replace; */
/* getnames=NO;guessingrows=max; */
/* run; */
proc import datafile="/home/cheng.zhong.shan/data/GTEx_V8/GTEX_AA_EA_others.txt" 
dbms=tab out=AA_info replace;
getnames=yes;guessingrows=max;
run;
data AA_info;
set AA_info;
rename Pop=var3	
IID=var1	
chr2_135566217_G_T_b38_T=snp	
Pop_hap=var2
;
run;
*Exclude Admixed Americal without AFR ancestry;
*The final samples will be EA and AA;
/* proc sql; */
/* create table tgt as  */
/* select a.*,b.snp, */
/*        b.Var2 as local_AFR, */
/*             case  */
/*             when length(b.Var1)>1 then 'AA' */
/*             else 'EA'  */
/*             end as AA */
/* from tgt as a */
/* left join */
/* AA_info as b */
/* on a.Var58=b.Var1; */

*Samples without AA information will be excluded;
proc sql;
create table tgt as 
select a.*,b.snp,
       b.Var2 as local_AFR,
           b.var3 as AA
from tgt as a,
AA_info as b
where a.Var58=b.Var1;

data tgt;
set tgt;
if not prxmatch("/(NotAA)/i",local_AFR);
AA_Sex=catx('',AA,'-',Sex);
AA_snp=catx('',put(snp,1.),'-',AA);
run;
/* %abort 255; */

*Delete the largest dataset exp;
proc datasets nolist;
delete exp;
run;

*Sort data tissues by the target gene;
proc sql;
create table avg4gene as
select cluster,avg(exp) as avg_tgt_gene from tgt 
where rownames="&gene4sort"
group by cluster
;
proc sql noprint;
create table avg4gene as
select unique(cluster) as cluster 
from avg4gene
order by avg_tgt_gene desc;
select quote(trim(left(cluster))) into: grps4boxplots1 - : grps4boxplots&sqlobs
from avg4gene;

*Also need to sort gene names in the header of lattice plot;
*Note: CAN apply format for the same dataset, targetdsd and fmtdsd;
*apply format to sort panel by a;
%rank4grps(
grps=&genes,dsdout=g
);
%mkfmt4grps_by_var(
grpdsd=g,
grp_var=grps,
by_var=num_grps,
outfmt4numgrps=x2y,
outfmt4chargrps=y2x
);
data tgt;
set tgt;
*format char grps to numeric grps;
new_rownames=input(rownames,x2y.);
run;

%end;
%else %do;
 %let dsd_headers=&Lib4PreviousDsd..headers;
 %let dsd_umap=&Lib4PreviousDsd..umap;
%end;

%let grpvar=Tissue;
%if %ntokens(&bygrps) eq 1 %then %do;
  %if %upcase("&bygrps")="SEX" %then %let grpvar=sex;
  %else %if %upcase("&bygrps")="SNP" %then %let grpvar=snp;
  %else %let grpvar=AA;
%end;
%else %if %sysfunc(prxmatch(/snp/i,&bygrps)) %then %do;
  %let grpvar=AA_snp;
%end;
%else %do;
  %let grpvar=AA_Sex;
%end;

title "GTEx gene expression boxplots";
*Make boxplot for target gene;
*It is very important to sort the data by cluster and new_sgrp!;
/* proc sort data=tgt;by rownames Tissue cluster; */
*Useful sas colornames;
*https://support.sas.com/content/dam/SAS/support/en/books/pro-template-made-easy-a-guide-for-sas-users/62007_Appendix.pdf;
ods graphics on/width=&boxplot_width height=&boxplot_height;
%let fontsize=7;
%if &UseGeneratedDsd=1 and &PreviousDsd ne %then %do;
%let workingdsd=tgt;
*Need to sort data tissues by the target gene;
*Here the tgt dsd was generated in the above steps but used here;
proc sql;
create table avg4gene as
select cluster,avg(exp) as avg_tgt_gene from tgt 
where rownames="&gene4sort"
group by cluster
;
proc sql noprint;
create table avg4gene as
select unique(cluster) as cluster 
from avg4gene
order by avg_tgt_gene desc;
select quote(trim(left(cluster))) into: grps4boxplots1 - : grps4boxplots&sqlobs
from avg4gene;
*Need to format data again;
%rank4grps(
grps=&genes,dsdout=g
);
%mkfmt4grps_by_var(
grpdsd=g,
grp_var=grps,
by_var=num_grps,
outfmt4numgrps=x2y,
outfmt4chargrps=y2x
);
data tgt;
set tgt;
*format char grps to numeric grps;
new_rownames=input(rownames,x2y.);
run;
%end;
%else %do;
 %let workingdsd=tgt;
%end; 
proc sgpanel data=&workingdsd;
%if %eval("&WhereFilters4Boxplot"^="") %then %do;
 where &WhereFilters4Boxplot;
%end;
panelby new_rownames/columns=1 novarname onepanel uniscale=column headerbackcolor=BWH
        headerattrs=(size=&fontsize) nowall noborder noheaderborder;
format new_rownames y2x.;
vbox exp/ group=&grpvar groupdisplay=cluster boxwidth=0.8 category=cluster
/*          outlierattrs=(color=grey symbol=circle size=2) */
/*          whiskerattrs=(color=grey thickness=1 pattern=1)  */
/*          medianattrs=(color=darkgreen thickness=1 pattern=1)  */
/*          meanattrs=(color=black symbol=circlefilled color=darkblue size=4) */
         outlierattrs=(color=black symbol=circlefilled size=4)
         whiskerattrs=(color=black thickness=1.5 pattern=3) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=darkblue symbol=circlefilled size=7)
         splitjustify=center grouporder=ascending
         SPREAD;

*In case of tissues were subsetted!;
%if %length(&WhereFilters4Boxplot)=0 %then %do;
colaxis fitpolicy=splitrotate 
valuesdisplay=(%do i=1 %to &sqlobs; 
          &&grps4boxplots&i
        %end;)
values=(%do i=1 %to &sqlobs; 
          &&grps4boxplots&i
        %end;)
valueattrs=(size=&fontsize) labelattrs=(size=&fontsize) label=" ";
%end;
%else %do;
colaxis fitpolicy=splitrotate;
%end;

rowaxis valueattrs=(size=&fontsize) labelattrs=(size=&fontsize) 
label="log2(TPM+1)";
keylegend / title="Group" titleattrs=(size=&fontsize) 
valueattrs=(size=&fontsize);
run;

*Outputthe final dataset;
%if %eval("&dsdout"^="exp") and (NOT %sysfunc(exist(&dsdout))) %then %do;
 *No need to change &dsdout to tgt when reusing previously generated dsd;
 *such as exp_all;
 proc datasets lib=work memtype=data nolist;
 change tgt=&dsdout;
 run; 
%end;


*12 genes: MAP3K19,R3HDM1,CXCR4,DARS,LCT, UBXN4, MCM6, ZRANB3, RAB3GAP1, CCNT2, ACMSD, TMEM163;

/* *options mprint mlogic symbolgen; */
/* %let glist=MAP3K19 R3HDM1 CXCR4 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163; */
/* %sc_glm4genes( */
/* dsd=sc.exp, */
/* dsd_headers=sc.headers, */
/* dsd_umap=sc.umap, */
/* genes=&glist, */
/* GLMStatOutDsd=GLMStatOut, */
/* GLM_classes=sex medication severity, */
/* GLM_model=severity sex age medication, */
/* samplewide=0, */
/* sample_var=sample, */
/* pheno_var=severity */
/* ); */
/*  */
/* *Make heatmap; */
/* data dsd4heatmap (keep=rownames cluster logP); */
/* set GLMStatOut; */
/* logP=-log10(probF); */
/* if logP<-log10(0.05/(12*21)) then logp=.; */
/* *if logP<1.3 then logp=.; */
/* if logP>50 then logP=50; */
/* where source="severity" and  */
/*       Cluster not contains 'Outlier'; */
/* label Cluster="Single cell types" rownames="Genes close rs16831827" */
/* logP="ANOVA -log10(P) among healthy control, severe, and critical COVID-19";       */
/* run; */
/*  */
/* %heatmap4longformatdsd( */
/* dsdin=dsd4heatmap, */
/* xvar=rownames, */
/* yvar=Cluster, */
/* colorvar=logP, */
/* fig_height=800, */
/* fig_width=800, */
/* outline_thickness=2 */
/* ); */
/*  */
%mend;

/*Demo:

*******************Run with downloaded data****************************;
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname GTEX '/home/cheng.zhong.shan/data/GTEx_V8';

*Note: the input gene order will be used to draw boxplots from up to down;
*%let genes=MAP3K19 CXCR4 R3HDM1 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163;
%let genes=MAP3K19 CXCR4;

*After running the follwoing macro once, it would be runnable again;
*by adjust the parameters of UseGeneratedDsd and Lib4PreviousDsd;
*with generated dataset exp_all;
*Even the 1st run may fail, once exp_all is generated, the macro can run it for it!;
%Boxplots4GenesInGTExV8ByGrps(
genes=&genes,
dsdout=exp,
bygrps=AA,
UseGeneratedDsd=0,
PreviousDsd=tgt,
Lib4PreviousDsd=GTEx,
WhereFilters4Boxplot=%str(),
boxplot_width=1800,
boxplot_height=800
);

*Get subset genes for using them later;
*exp_all was generated by the above sas macro internally;
proc print data=exp_all(obs=10);var rownames;run;
data GTEX.target_genes;
set exp_all;
where scan(rownames,2,'|') in (
'MAP3K19'
'MCM6'
'DARS'
'CXCR4'
'MCM6'
'RAB3GAP1'
'R3HDM1'
'ZRANB3'
'UBXN4'
'DARS1'
'CCNT2'
'TMEM168'
'IFNG'
'IFNB'
'IFNA'
);
run;


*******************Run with generated data****************************;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname GTEX '/home/cheng.zhong.shan/data/GTEx_V8';

*Note: the input gene order will be used to draw boxplots from up to down;
%let genes=MAP3K19 CXCR4 R3HDM1 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163 IFNG IFNA IFNB;
*%let genes=MAP3K19 CXCR4;
data exp_all;set GTEX.target_genes;run;
data headers;set GTEX.headers;run;
*Use generated dataset exp_all or GTEX.target_genes;
*options mprint mlogic symbolgen;
*The macro is with bug, when using previously generated dsd;
*Need to asign dsdout exp_all and PreviousDsd as empty string;
*The bug is due to the macro var PreviousDsd is fixed to be 'tgt';
*So it is arbitary to asign macro var PreviousDsd as 'tgt' whenever using previous dsd;
%Boxplots4GenesInGTExV8ByGrps(
genes=&genes,
dsdout=exp_all,
bygrps=AA snp,
UseGeneratedDsd=1,
PreviousDsd=tgt,
Lib4PreviousDsd=work,
WhereFilters4Boxplot=%str( cluster in ('Testis' 'Lung') and AA='AA'),
boxplot_width=400,
boxplot_height=1600
);

%exportds2gz(
dsdin=tgt,
outgz=MAP3K19_CXCR4_GTEx_exp,
outdir=/home/cheng.zhong.shan/data
);

proc datasets lib=work;
run;

proc sort data=tgt;by rownames tissue AA;run;
ods graphics on/height=400 width=400;
proc glm data=tgt;
*where tissue in ('Testis' 'Lung');
*class tissue AA_sex age dthhrdy;
*model exp=AA_sex age dthhrdy;
*lsmeans AA_sex/pdiff;
class tissue AA;
model exp=AA;
lsmeans AA/pdiff;
by rownames tissue;
run;

*The DTHHRDY column encodes the death classification based on;
*the 4-point Hardy Scale. The coding corresponds to the following categories:;
*0: Ventilator Case; 1: Violent and fast death; 2: Fast death of natural 
*causes; 3: Intermediate death; 4: Slow death;

proc sort data=tgt;by rownames tissue;run;
ods graphics on/height=400 width=400;
proc glm data=tgt;
where tissue in ('Testis' 'Lung');
class tissue AA_sex;
model exp=AA_sex;
lsmeans AA_sex/pdiff;
by rownames tissue;
run;

*MAP3K19 in lung by sex and AA;
*For 117 AA samples;
*When only consider pure AA samples, the results are different;
*AA-M vs. EA-M p=0.56;
*AA-M vs. EA-F p=0.0755;
*AA-M vs. AA-F p=0.37
*EA-M vs. EA-F p=0.068

*MAP3K19 in testis by sex;
*AA-M vs. EA-M p=0.0041;

proc tabulate data=tgt;
class rownames tissue AA cluster sex;
table cluster*rownames,(AA*sex n);
run;

*/

