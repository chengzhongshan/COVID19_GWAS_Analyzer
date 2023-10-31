%macro sc_scatter4gene(
dsd=,
dsd_headers=,
dsd_umap=,
gene=,
cell_type_var=cluster,
pheno_var=,
pheno_categories=,
grpvar4boxplot=,/*separate umap and boxplot by pheno_var and grpvar*/
samplewide=0,
sample_var=sample,
boxplot_width=1000,
boxplot_height=600,
umap_width=1000,
umap_height=500,
umap_lattice_nrows=1,
boxplot_nrows=3,
where_cnd4sgplot=,
rgx2cells_not_matched_as_other=  /*the rgx will be put inside: not prxmatch function*/
);
/* libname sc "/home/cheng.zhong.shan/data"; */
*Need to have sc.exp, sc.UMAP;
%let ncats=%ntokens(&pheno_categories);

*determine whether there is supplied group variable to create umap and boxplot by pheno_var and group var;
*If no group var supplied, only pheno_var will be used to draw umap and boxplot by it;
%if %length(&grpvar4boxplot) > 0 %then %do;
  %let gtag=1;
%end;
%else %do;
  %let gtag=0;
%end;

/* proc print data=sc.exp(obs=10); */
/* var rownames v1-v100; */
/* run; */
data _tgt_dsd_;
set &dsd;
where rownames="&gene" or 
           scan(rownames,2,'|')="&gene"  or
           scan(rownames,1,'|')="&gene";
run;
*transpose wide data into long format data;
data _tgt_dsd_;
set _tgt_dsd_;
array X{*} _numeric_;
do i=1 to dim(X);
 *Since the var i NOT always contain the required variable order;
 xi=prxchange('s/V//',-1,vname(X{i}))+0;
 exp=X{i};
 output;
end;
drop i V:;
run;
/* proc sgplot data=_tgt_dsd_; */
/* histogram exp; */
/* run; */
/* proc print data=sc.umap(obs=10); */
/* proc print data=sc.headers(obs=10); */
/* proc print data=_tgt_dsd_(obs=10); */
/* run; */
proc sql;
create table _tgt_dsd_ as
select a.*,c.*
from _tgt_dsd_ as a,
     &dsd_headers as b,
     &dsd_umap as c
where c.seq_id=b.colnames and a.xi=b.i; 
data _tgt_dsd_;
set _tgt_dsd_;
*Add 1 for exp and transform it with log2;
exp=log2(exp+1);

/* if severity="control_healthy" then sgrp=1; */
/* else if severity="severe" then sgrp=2; */
/* else sgrp=3; */
sgrp=-9;
%do ci=1 %to &ncats;
   %let cat_val=%scan(&pheno_categories,&ci);
   if &pheno_var="&cat_val" then sgrp=&ci;
%end;

label x="UMAP_1" y="UMAP_2"
      exp="log2(normalized expression + 1)";
*remove outlier &cell_type_var
s;
where &cell_type_var
 not contains 'Outlier';    
run;

%if %length(&rgx2cells_not_matched_as_other)>0 %then %do;
*combine specific cell types as other;
data _tgt_dsd_;
set _tgt_dsd_;
if not prxmatch("/&rgx2cells_not_matched_as_other/",&cell_type_var
) then do;
   &cell_type_var
='Other';
end;
run;
%end;


%mkfmt4grpsindsd(
targetdsd=_tgt_dsd_,
grpvarintarget=&pheno_var,
name4newfmtvar=new_sgrp,
fmtdsd=_tgt_dsd_,
grpvarinfmtdsd=&pheno_var,
byvarinfmtdsd=sgrp,
finaloutdsd=new__tgt_dsd_
);


%if %eval(&gtag=1) %then %do;
title "Single cell expression UMAP for &gene by &grpvar4boxplot";
%end;
%else %do;
title "Single cell expression UMAP plot for &gene";
%end;    

ods graphics on/reset=all width=&umap_width height=&umap_height noborder imagename="UMAP4&dsd";
proc sgpanel data=new__tgt_dsd_;
 *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of;
 *colors with 2nd datasymbols, and the same applied to other datasymbols;
 styleattrs datacontrastcolors=(green gold red black blue grey pink)  
            datasymbols=(circlefilled starfilled triangle diamond square circle) ;
*where &cell_type_var
 contains 'Ciliated';
panelby new_sgrp %if %eval(&gtag=1) %then %do;
                 &grpvar4boxplot /layout=lattice novarname;
                 %end;
                 %else %do;
                 /onepanel rows=&umap_lattice_nrows novarname;
                 %end;
scatter x=x y=y /group=cluster
 colorresponse=exp 
                 colormodel=(lightgray gold red) ;
run;

*Use samplewide avg but not median expression for plotting;
*Note: it is necessary to include 0 values when calculating samplewide avg exp;
%if &samplewide and &sample_var ne %then %do;
 proc sql;
 create table new__tgt_dsd_ as
 select &sample_var, &pheno_var, new_sgrp, &cell_type_var, avg(exp) as exp
 %if %eval(&gtag=1) %then %do;
 ,&grpvar4boxplot
 %end;
 from new__tgt_dsd_
 group by &sample_var, &cell_type_var,new_sgrp  
 %if %eval(&gtag=1) %then %do;
 ,&grpvar4boxplot
 %end;
 ;
%end;

%if %eval(&gtag=1) %then %do;
title "Single cell expression boxplots for &gene by &grpvar4boxplot";
%end;
%else %do;
title "Single cell expression boxplots for &gene";
%end;

*Make boxplot for target gene;
*It is very important to sort the data by &cell_type_var
 and new_sgrp!;
proc sort data=new__tgt_dsd_;by &cell_type_var
 %if %eval(&gtag=1) %then %do;
 &grpvar4boxplot
 %end;
 new_sgrp;
ods graphics on/reset=all width=&boxplot_width height=&boxplot_height noborder imagename="ExpBoxplot4&dsd";
proc sgpanel data=new__tgt_dsd_
%if %length(&where_cnd4sgplot)>0 %then %do;
 %*need to unquote it for correct resolution the macro var;
 (where=(%unquote(&where_cnd4sgplot)))
%end;
;

panelby &cell_type_var 
/rows=&boxplot_nrows novarname onepanel;
*Add category=&new_sgrp or other var will display xaxis for boxplot;
vbox exp/
 %if %eval(&gtag=1) %then %do;
  group=&grpvar4boxplot category=new_sgrp
 %end;
 %else %do;
  group=new_sgrp
 %end;
 groupdisplay=&cell_type_var
 boxwidth=0.6
         outlierattrs=(color=black symbol=circlefilled size=4)
         whiskerattrs=(color=black thickness=1 pattern=2) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=black symbol=circlefilled color=darkgreen size=8)
         fillattrs=(transparency=0.5);
keylegend /noborder valueattrs=(size=8);         
label new_sgrp="Group";         
run;

/* libname sc clear; */
%mend;

/*Demo:
*options mprint mlogic symbolgen;
*/
/* *options mprint mlogic symbolgen; */
/* %let macrodir=/home/cheng.zhong.shan/Macros; */
/* %include "&macrodir/importallmacros_ue.sas"; */
/* %importallmacros_ue; */
/* libname sc "/home/cheng.zhong.shan/data"; */
/*  */
/* *Download UMAP gz file; */
/* %let httpfile_url=https://cells.ucsc.edu/covid19-cellular-targets/heart/all/UMAP.coords.tsv.gz; */
/* *In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!; */
/* %dwn_http_file(httpfile_url=&httpfile_url,outfile=Seurat_umap.coords.tsv.gz,outdir=%sysfunc(getoption(work))); */
/*  */
/* *Import UMAP gz file into SAS; */
/* %ImportFileHeadersFromZIP( */
/* zip=%sysfunc(getoption(work))/Seurat_umap.coords.tsv.gz, */
/* filename_rgx=., */
/* obs=max, */
/* sasdsdout=x, */
/* deleteZIP=0, */
/* infile_command=%str( */
/* obs=max delimiter='09'x truncover; */
/* length seq_ID $200.; */
/* input seq_ID $ x y;) */
/* ); */
/*  */
/* *Download cell type and other meta info; */
/* filename meta url 'https://cells.ucsc.edu/covid19-cellular-targets/heart/all/meta.tsv'; */
/* proc import datafile=meta dbms=tab out=info replace; */
/* getnames=yes;guessingrows=max; */
/* run; */
/*  */
/* *Add meta info into UMAP dataset; */
/*  */
/* proc print data=x(obs=10); */
/* proc print data=info(obs=10); */
/* run; */
/*  */
/* proc sql; */
/* create table sc.UMAP as  */
/* select a.*,b.* */
/* from x as a, */
/*      info as b */
/* where a.seq_ID=b.cellid; */
/*  */
/* *Remove table x to release space; */
/* proc sql; */
/* drop table x; */
/*  */
/* *Draw scatterplot of UMAP;     */
/* proc sgplot data=sc.UMAP; */
/* scatter x=x y=y/group=cluster
; */
/* run; */
/*  */
/* %add_symbol4grp_in_dsd( */
/* dsdin=UMAP, */
/* grp_var=&cell_type_var
, */
/* symbols=%nrstr(+ * | a b c d e f g h i y z w n h m n r w q), */
/* dsdout=UMAP1); */
/*  */
/* ods graphics on/width=600 height=1000; */
/* proc sgpanel data=UMAP1; */
/* where &cell_type_var
 contains 'Ciliated'; */
/* panelby severity/onepanel columns=1 novarname; */
/* scatter x=x y=y/group=cluster
 markerchar=symbol_grp; */
/* run; */
/*  */
/*  */
/* *Better way is to use datacontrastcolors and datasymbols for sgpanel; */
/* ods graphics on/width=800 height=400; */
/* proc sgpanel data=sc.UMAP; */
/*  *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of; */
/*  *colors with 2nd datasymbols, and the same applied to other datasymbols; */
/*  styleattrs datacontrastcolors=(green gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle) ; */
/* where &cell_type_var
 contains 'Ciliated'; */
/* panelby disease sex/onepanel rows=1 novarname; */
/* scatter x=x y=y/group=cluster
; */
/* run; */
/*  */
/* *Now download UCSC single cell gene expression data; */
/* %ucsc_cell_matrix2wideformatdsd( */
/* gzfile_or_url=https://cells.ucsc.edu/covid19-cellular-targets/heart/all/exprMatrix.tsv.gz, */
/* dsdout4headers=sc.headers, */
/* dsdout4data=sc.exp */
/* ); */
/* proc contents data=sc.exp noprint out=exp_vars; */
/* run; */
/*  */
/* *Try to select data columns randomly; */
/* *Only 20% cells will be selected for analysis and plotting; */
/* *This will save space in SAS ondemand!; */
/* %macro subset_exp; */
/* data sampling(keep=vars rnd_n); */
/* length vars $100; */
/* set headers; */
/* rnd_n=rand("uniform",0,1); */
/* vars=compress('V'||_n_); */
/* ; */
/* run; */
/* proc sql noprint; */
/* select count(*) into: totrows */
/* from sampling; */
/* %let totrows=%sysfunc(left(&totrows)); */
/* *Only 50% columns will be selected; */
/* %let sn=%sysevalf(&totrows*0.2,floor); */
/* proc sort data=sampling out=sampling;by rnd_n; */
/* data sampling; */
/* set sampling; */
/* if _n_>&sn; */
/* run; */
/* proc sql noprint; */
/* select vars into: var%eval(&sn+1)-:var&totrows */
/* from sampling; */
/* *Subset columns by dropping some cols; */
/* data exp; */
/* set exp; */
/* drop  */
/* %do i=%eval(&sn+1) %to &totrows; */
/*  &&var&i */
/* %end; */
/* ; */
/* run; */
/* %mend; */
/* %subset_exp; */
/*  */
/* *A better macro was written;; */
/* *%random_subset_cols4dsd(; */
/* *dsdin=exp,; */
/* *rgx2matchcols=%str(^V),; */
/* *rgx2fixedcols=%str(^rownames),; */
/* *rnd_pct=0.1,; */
/* *dsdout=exp; */
/* *);; */
/*  */
/* *proc contents data=exp out=exp_vars noprint; */
/* *run; */
/*  */
/* *perform deseq normalization for single cell expression data; */
/* data exp; */
/* set sc.exp; */
/* tag=mean(of _numeric_)>=1; */
/* if tag; */
/* run; */
/* %deseq_normalization( */
/* dsdin=sc.exp, */
/* read_vars=_numeric_, */
/* dsdout=exp, */
/* readcutoff=3, */
/* cellcutoff=500 */
/* ); */
/*  */
/*  */
/* *Successfully generated normalized single cell expression data; */
/* *Move data into lib sc; */
/* libname sc "/home/cheng.zhong.shan/data"; */
/* proc datasets nolist; */
/* copy in=work out=sc memtype=data move; */
/* select exp headers umap ; */
/* run; */
/* libname sc clear; */
/*  */
/* *remove all temporary datasets in work lib to release spaces; */
/* proc datasets lib=work nolist kill; */
/* run; */
/*  */
/* *****************************run analysis here****************************************; */
/* *options mprint mlogic symbolgen; */
/* %let macrodir=/home/cheng.zhong.shan/Macros; */
/* %include "&macrodir/importallmacros_ue.sas"; */
/* %importallmacros_ue; */
/* libname sc "/home/cheng.zhong.shan/data"; */
/*  */
/* ods graphics on/width=1000 height=800; */
/* proc sgplot data=sc.UMAP; */
/* scatter x=x y=y/group=cluster
; */
/* label x="UMAP_1" y="UMAP_2"; */
/* run; */
/* *Better way is to use datacontrastcolors and datasymbols for sgpanel; */
/* ods graphics on/width=1000 height=600; */
/* proc sgpanel data=sc.UMAP; */
/*  *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of; */
/*  *colors with 2nd datasymbols, and the same applied to other datasymbols; */
/*  styleattrs datacontrastcolors=(green gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle) ; */
/* where &cell_type_var
 contains 'Ciliated'; */
/* panelby disease/onepanel rows=1 novarname; */
/* scatter x=x y=y/group=cluster
; */
/* label x="UMAP_1" y="UMAP_2"; */
/* run; */
/*  */
/*  */
/* *MAP3K19 paper; */
/* %sc_scatter4gene(gene=MAP3K19); */
/* %sc_scatter4gene(gene=R3HDM1); */
/* %sc_scatter4gene(gene=CXCR4); */
/* %sc_scatter4gene(gene=DARS1); */
/* %sc_scatter4gene(gene=LCT); */
/* %sc_scatter4gene(gene=UBXN4); */
/* %sc_scatter4gene(gene=MCM6); */
/* %sc_scatter4gene(gene=ZRANB3); */
/* %sc_scatter4gene(gene=RAB3GAP1); */
/* %sc_scatter4gene(gene=CCNT2); */
/* %sc_scatter4gene(gene=ACMSD); */
/* %sc_scatter4gene(gene=TMEM163); */
/*  */
/*  */
/* *sex-diff covid-19 gwas paper; */
/* proc sql; */
/* select unique(disease) */
/* from sc.umap; */
/*  */
/* %sc_scatter4gene(dsd=exp,dsd_headers=sc.headers,dsd_umap=sc.umap,gene=SPEG,pheno_var=disease,pheno_categories=COVID19 healthy); */
/* %sc_scatter4genebygrp(dsd=exp,dsd_headers=sc.headers,dsd_umap=sc.umap,gene=SPEG,pheno_var=disease,pheno_categories=COVID19 healthy,grpvar4boxplot=sex); */
/*  */
/*  */
/* *%sc_scatter4gene(gene=PVRL1); */
/* proc export data=_tgt_dsd_ outfile="/home/cheng.zhong.shan/Map3k19.exp.txt" */
/* dbms=tab replace; */
/* run; */
/* libname sc "/home/cheng.zhong.shan/data"; */
/* proc sql;select unique(severity) from sc.UMAP;quit; */
/*  */
/* *Check whether data were normalized; */
/* libname sc "/home/cheng.zhong.shan/data"; */
/* data x; */
/* set sc.exp; */
/* where rownames="MAP3K19"; */
/* run; */
/* data x; */
/* set x; */
/* array X{*} _numeric_; */
/* do i=1 to dim(X); */
/*  exp=X{i}; */
/*  output; */
/* end; */
/* drop V:; */
/* run; */
/* proc sql; */
/* select count(*)  */
/* from x */
/* where floor(exp)<exp; */
/*  */
/*  */

