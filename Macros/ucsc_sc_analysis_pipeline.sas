*Note: this macro is not updated with newly created macros for downloading ucsc gene expression matrix;
*and the macro of importing single cell gene expression, making UMAP, and other visualizaiton macros;
*these new macros have been written for the STAR Protocol paper of COVID19_GWAS_Analyzer;

%macro ucsc_sc_analysis_pipeline(
remove_pre_sc_sas_dsds=0,	/*provide 1 to remove all previous sc datasets, such as exp, headers, umap*/
sc_lib_path=/home/cheng.zhong.shan/data,
umap_http_link=https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz,
exprMatrix_http_link=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
meta_http_link=https://cells.ucsc.edu/covid-hypertension/meta.tsv,

cellid_in_meta_tsv=cellid, 
/*this should be the first column name from the meta tsv; 
it is variable from difference sc meta tsv, such as cellid or cell;*/

pheno_var=disease,
ordered_pheno_categories=healthy COVID19,
cell_type_var=cluster,
grpvar4boxplot=,
tgt_genes_in_order=SPEG CD55,
rgx4_not_matched_cells_as_others=cardiomyocyte,

/*for umap scatterplot and aggregrated sc boxplot*/
samplewide=0,
sample_var=,
AllCellsboxplot_width=300,
AllCellsboxplot_height=800,
umap_width=1000,
umap_height=400,
umap_lattice_nrows=1,
AllCellsboxplot_nrows=5,

/*for sc percent visualization*/
frqboxplot_height=800,
frqboxplot_width=300,
frqboxplot_nrows=2,
frqwhere_cnd_for_sgplot=%quote(),
other_glm_classes=sex,

/*UMAP by pheno with text label setting*/
alt_umap_cell_height=400,
alt_umap_total_width=800,

/*UMAP for all single cells setting*/
umap4all_cells_height=800,
umap4all_cells_width=800,

/*Perform sample level exp analysis: 
-1: no single cell level and sample level; 
1: yes for sample leve only; 0: yes only for single cell level
2: both at single cell and sample level;
Note: median will be used to calculate sample leve expression;
*/
sample_level_exp_analysis=1

);

%if %FileOrDirExist(&sc_lib_path) %then %do;
 %put your input sc lib fullpath is &sc_lib_path, which exists!;
%end;
%else %do;
 %put your input sc lib fullpath is &sc_lib_path, which does not exists!;
	%abort 255;
%end;

libname sc "&sc_lib_path";

%if &remove_pre_sc_sas_dsds=1 %then %do;
	proc datasets lib=sc;
	delete exp headers umap;
	run;
%end;

%if (not %chk_sas_dsd(lib=sc,dsdname=exp)) and 
(not %chk_sas_dsd(lib=sc,dsdname=umap)) and 
(not %chk_sas_dsd(lib=sc,dsdname=headers))
%then %do;
*Download UMAP gz file;
%let httpfile_url=&umap_http_link;
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
input seq_ID :$200. x y;)
);

*Download cell type and other meta info;
filename meta url "&meta_http_link";
proc import datafile=meta dbms=tab out=info replace;
getnames=yes;guessingrows=max;
run;

*Add meta info into UMAP dataset;
/*
proc print data=x(obs=10);
proc print data=info(obs=10);
run;
*/

proc sql;
create table UMAP as 
select a.*,b.*
from x as a,
     info as b
where a.seq_ID=b.&cellid_in_meta_tsv;
*Note: this part would be have problem if the cellid is change in info dsd from the meta tsv file;
%if %sysfunc(exist(UMAP)) %then %do;
 %put the sc UMAP is created by merging between meta and umap data sets;
%end;
%else %do;
 %put Please check the seq_ID and &cellid_in_meta_tsv or cell from the two sas dataset x and info, respectively;
%end;



/* *Draw scatterplot of UMAP;     */
/* proc sgplot data=UMAP; */
/* scatter x=x y=y/group=&cell_type_var; */
/* run; */
/*
%add_symbol4grp_in_dsd(
dsdin=UMAP,
grp_var=&cell_type_var,
symbols=%nrstr(+ * | a b c d e f g h i y z w n h m n r w q),
dsdout=UMAP1);

ods graphics on/width=600 height=1000;
proc sgpanel data=UMAP1;
where &cell_type_var contains 'Ciliated';
panelby &pheno_var/onepanel columns=1 novarname;
scatter x=x y=y/group=&cell_type_var markerchar=symbol_grp;
run;
*/

/* *Better way is to use datacontrastcolors and datasymbols for sgpanel; */
/* ods graphics on/width=800 height=400 noborder; */
/* proc sgpanel data=UMAP; */
/*  *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of; */
/*  *colors with 2nd datasymbols, and the same applied to other datasymbols; */
/*  styleattrs datacontrastcolors=(green gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle) ; */
/* where &cell_type_var contains 'Ciliated'; */
/* panelby &pheno_var/onepanel rows=1 novarname; */
/* scatter x=x y=y/group=&cell_type_var; */
/* run; */

*Now download UCSC single cell gene expression data;
%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=&exprMatrix_http_link,
dsdout4headers=headers,
dsdout4data=exp
);

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
*perform deseq normalization for single cell expression data;
*Only in WIN system, perform normalization;

/* %if "&sysscp"="WIN" %then %do; */
 %deseq_normalization( 
 dsdin=exp, 
 read_vars=_numeric_, 
 dsdout=exp, 
 readcutoff=3, 
 cellcutoff=200 
 ); 
/*  %abort 255; */
/* %end; */
*Successfully generated normalized single cell expression data;
*Move data into lib sc;

proc datasets nolist;
copy in=work out=sc memtype=data move;
select exp headers umap ;
run;

/* %abort 255; */
%end;
%else %do;
 %put Use previously generated single cell data sets;
%end;


*****************************run analysis here****************************************;
ods graphics on/width=&umap4all_cells_width height=&umap4all_cells_height noborder;
title "UMAP with cell type labels for all single cells";
proc sgplot data=sc.UMAP;
scatter x=x y=y/group=&cell_type_var;
label x="UMAP_1" y="UMAP_2";
run;

*Better way is to use datacontrastcolors and datasymbols for sgpanel;
*Only plot 20% cells;
proc sql noprint;
select count(*) into: tot_cells
from sc.UMAP;

%Sampling(indsd=sc.UMAP,n=%sysevalf(&tot_cells*0.2,ceil),nperm=1,dsdout=sub_umap);

*Need to change this, as card commands can not be run within macro;
/* data g; */
/* length &pheno_var $20.; */
/* input &pheno_var $ y; */
/* cards; */
/* control_healthy 1 */
/* severe 2 */
/* critical 3 */
/* ; */

%rank4grps(
grps=&ordered_pheno_categories,
dsdout=g
);
data g(keep=&pheno_var y);
set g;
&pheno_var=grps;
y=num_grps;
run;

%mkfmt4grpsindsd(
targetdsd=sub_umap,
grpvarintarget=&pheno_var,
name4newfmtvar=new_&pheno_var,
fmtdsd=g,
grpvarinfmtdsd=&pheno_var,
byvarinfmtdsd=y,
finaloutdsd=sub_map_fmted
);

/* data sub_map_fmted; */
/* set sub_map_fmted; */
/* &cell_type_var=lowcase(&cell_type_var); */
/* run; */
/* proc print data=sub_map_fmted(obs=10);run; */

******************add group means of x and y for labeling;
*This is not the best soluation to put labels for clusters;
/* proc sql; */
/* create table sub_map_fmted as */
/* select a.*, mean(x) as x_,mean(y) as y_ */
/* from sub_map_fmted as a */
/* group by &cell_type_var, &pheno_var */
/* order by &cell_type_var, &pheno_var; */
proc sql;
select count(unique(&pheno_var)) into: n_phenos
from sub_map_fmted;

/* data sub_map_fmted; */
/* set sub_map_fmted; */
/* *This may be variable due to some clusters are not compacted!; */
/* if not last.&cell_type_var and not last.&pheno_var then do; */
/*   x_=.;y_=.; */
/* end; */
/* by &cell_type_var &pheno_var; */
/* run; */

*Make sure to use new_&pheno_var, as it but not &pheno_var will be used by pro sgplot penal by statement;
%groupsummary(
dsdin=sub_map_fmted,
grps=&cell_type_var new_&pheno_var,
vars4summary=x y,
funcs4var=mean,
dsdout=sub_map_fmted,
include_org_dsd_in_output=1
);

/* ods graphics on/width=1200 height=600; */
ods graphics on/width=&alt_umap_total_width 
height=%sysevalf(&n_phenos*&alt_umap_cell_height,ceil) 
noborder;
title "UMAP with cell type labels for randomly sampled single cells";
proc sgpanel data=sub_map_fmted;
/* where &cell_type_var not in ('Outlier' 'Outlier2') ; */
where &cell_type_var not in ('Outlier' 'Outlier2') and &cell_type_var contains 'iliated';
 *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of;
 *colors with 2nd datasymbols, and the same applied to other datasymbols;
/*  styleattrs datacontrastcolors=(green dardyellow gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle); */
 styleattrs datacontrastcolors=(green darkgreen blueviolet lightcoral bio bippk gold vlipb vlib blueviolet lightpink lightsalmon)
            datasymbols=(circlefilled starfilled triangle diamond square circle);
/* where &cell_type_var contains 'Ciliated'; */
panelby new_&pheno_var/onepanel rows=&n_phenos novarname;
scatter x=x y=y/group=&cell_type_var markerattrs=(size=3);
text x=x_mean y=y_mean text=&cell_type_var / textattrs=(size=10 weight=bold color=darkred);
label x="UMAP_1" y="UMAP_2";
run;
/* %abort 255; */

****************************Important codes to make boxplot and perform GLM analysis********************************;
%macro sc_visulization4gene(gene);

%sc_scatter4gene(
dsd=sc.exp,
dsd_headers=sc.headers,
dsd_umap=sc.umap,
gene=&gene,
pheno_var=&pheno_var,
pheno_categories=&ordered_pheno_categories,
grpvar4boxplot=&grpvar4boxplot,
samplewide=0,
sample_var=,
boxplot_width=&AllCellsboxplot_width,
boxplot_height=&AllCellsboxplot_height,
umap_width=&umap_width,
umap_height=&umap_height,
umap_lattice_nrows=&umap_lattice_nrows,
boxplot_nrows=&AllCellsboxplot_nrows,
where_cnd4sgplot=,
rgx2cells_not_matched_as_other=&rgx4_not_matched_cells_as_others
);
*%quote(&cell_type_var contains %'iliated%');
%mend;

%do gi=1 %to %ntokens(&tgt_genes_in_order);
   %let gene=%scan(&tgt_genes_in_order,&gi);
   title "Single cell analysis for gene &gene";
   %sc_visulization4gene(gene=&gene);
  *Use the dataset _tgt_dsd_ generated by above to run the macro;
  *Working with temporary data tgt&gi;
  data tgt&gi;
  %if %length(&grpvar4boxplot)>0 %then %do;
  length cell_type $50. pheno_by_grps $50.;  
  %end;
  %else %do;
  length cell_type $50.;
  %end;
  set _tgt_dsd_;
  *Make cell types not matched with rgx as 'Other';
  cell_type="Other";
  if prxmatch("/&rgx4_not_matched_cells_as_others/",&cell_type_var) then cell_type=&cell_type_var;
  %if %length(&grpvar4boxplot)>0 %then %do;
    pheno_by_grps=catx('_',&pheno_var,&grpvar4boxplot);
  %end;
  run;
  
  %if %length(&grpvar4boxplot)>0 %then %do;
    *Do not replace original macro var &pheno_var;
    %let _pheno_var_=pheno_by_grps;
  proc sql noprint;
  select unique(&_pheno_var_) into: ordered_pheno_categories separated by ' '
  from tgt&gi;
  %end;
  %else %do;
    %let _pheno_var_=&pheno_var;
  %end;
  
  *Get percent of different cells;
  *Note: we use the exp_cutoff=-1;
  *This will calcuate the percents of different cells within each pheno group;
  *percent=cells/total_cells_in_a_pheno_grp;
  %sc_freq_boxplot(
  longformdsd=tgt&gi,
  cell_type_var=cell_type,
  sample_grp_var=sample,
  pheno_var=&_pheno_var_,
  cust_pheno_order=&ordered_pheno_categories,
  exp_var=exp,
  exp_cutoff=-1,
  boxplot_height=&frqboxplot_height,
  boxplot_width=&frqboxplot_width,
  boxplot_nrows=&frqboxplot_nrows,
  where_cnd_for_sgplot=%quote(),
  frqout=&gene._cellfrqout,
  other_glm_classes=&other_glm_classes,
  aggre_sc_glm_pdiff_dsd=&gene._all_sc,
  sample_level_exp_analysis=&sample_level_exp_analysis
  );

  *This will calcuate the percents cells passing the exp threshold among its total number of corresponding cells;
  *percent=cells_expressed_gene/total_cells_of_specific_type;
  %sc_freq_boxplot(
  longformdsd=tgt&gi,
  cell_type_var=cell_type,
  sample_grp_var=sample,
  pheno_var=&_pheno_var_,
  cust_pheno_order=&ordered_pheno_categories,
  exp_var=exp,
  exp_cutoff=0,
  boxplot_height=&frqboxplot_height,
  boxplot_width=&frqboxplot_width,
  boxplot_nrows=&frqboxplot_nrows,
  where_cnd_for_sgplot=%quote(),
  frqout=&gene._exp_cellfrqout,
  other_glm_classes=&other_glm_classes,
  aggre_sc_glm_pdiff_dsd=&gene._all_sc,
  sample_level_exp_analysis=&sample_level_exp_analysis
  );
%end;


***************************************************************;

/* *Combine data for making boxplots for diff-ciliated cells; */
/* data sc.Cilia; */
/* set single_gene_:; */
/* run; */

/* ***********************Run analysis with saved data*************************; */
/* *options mprint mlogic symbolgen; */
/* %let macrodir=/home/cheng.zhong.shan/Macros; */
/* %include "&macrodir/importallmacros_ue.sas"; */
/* %importallmacros_ue; */
/* libname sc "/home/cheng.zhong.shan/data"; */
/*  */
/* data cilia; */
/* set sc.cilia; */
/* if &pheno_var="control_healthy" then sgrp=1; */
/* else if &pheno_var="severe" then sgrp=2; */
/* else sgrp=3; */
/* where &cell_type_var contains ("Ciliated"); */
/* run; */
/* *CFAP70 alias TTC18; */
/* *CFAP46 alias TTC40; */
/* data cilia; */
/* set cilia; */
/* if rownames="TTC18" then rownames="CFAP70"; */
/* if rownames="TTC40" then rownames="CFAP46"; */
/* run; */
/*  */
/* %mkfmt4grpsindsd( */
/* targetdsd=cilia, */
/* grpvarintarget=&pheno_var, */
/* name4newfmtvar=new_sgrp, */
/* fmtdsd=cilia, */
/* grpvarinfmtdsd=&pheno_var, */
/* byvarinfmtdsd=sgrp, */
/* finaloutdsd=new_tgt */
/* ); */
/*  */
/* proc sql; */
/* create table new_tgt as  */
/* select rownames,sample,&cell_type_var,mean(exp) as exp,sex,medication, */
/*        new_sgrp,sgrp */
/* from new_tgt */
/* group by rownames,sample,&cell_type_var; */
/*  */
/* proc sort data=new_tgt nodupkeys; */
/* by sample rownames &cell_type_var sex medication exp; */
/* run; */
/*  */
/* proc sort data=new_tgt;by rownames &cell_type_var new_sgrp; */
/* options printerpath=svg; */
/* ods listing close; */
/* ods printer; */
/* ods graphics on /reset height=400 width=800 noborder imagename='boxplot.svg'; */
/* proc sgpanel data=new_tgt; */
/* panelby rownames &cell_type_var /novarname onepanel layout=lattice uniscale=column; */
/* vbox exp /groupdisplay=&cell_type_var group=new_sgrp grouporder=ascending boxwidth=0.6 */
/*          outlierattrs=(color=black symbol=circle size=4) */
/*          whiskerattrs=(color=black thickness=1 pattern=2)  */
/*          medianattrs=(color=black thickness=2 pattern=1)  */
/*          meanattrs=(color=black symbol=circlefilled color=darkblue size=5); */
/* label new_sgrp="COVID-19";            */
/* run; */
/* ods printer close; */
/* ods listing; */
/* *options mprint mlogic symbolgen; */
/* %let glist=MAP3K19 R3HDM1 CXCR4 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163; */
/* %let glist=WDR78 MAPK15 LRRC71 TTC18 TTC40 CCDC60 CRISP3 C11orf88 MAP3K19; */
/* %sc_glm4genes( */
/* dsd=sc.exp, */
/* dsd_headers=sc.headers, */
/* dsd_umap=sc.umap, */
/* genes=&glist, */
/* GLMStatOutDsd=GLMStatOut, */
/* GLM_classes=sex medication &pheno_var, */
/* GLM_model=&pheno_var sex age medication, */
/* samplewide=0, */
/* sample_var=sample, */
/* pheno_var=&pheno_var */
/* ); */
/* data GLMStatOut; */
/* set GLMStatOut; */
/* if source="&pheno_var"; */
/* run; */
/* proc print;run; */
/*  */
/* ***********************************************************; */
/* *12 genes: MAP3K19,R3HDM1,CXCR4,DARS,LCT, UBXN4, MCM6, ZRANB3, RAB3GAP1, CCNT2, ACMSD, TMEM163; */
/*  */
/* *options mprint mlogic symbolgen; */
/* %let glist=MAP3K19 R3HDM1 CXCR4 DARS LCT UBXN4 MCM6 ZRANB3 RAB3GAP1 CCNT2 ACMSD TMEM163; */
/* %let glist=MAPK15 TTC18 TTC40 MAP3K19 DRC1 DNAI2 EFHC2 SPEF2; */
/* %sc_glm4genes( */
/* dsd=sc.exp, */
/* dsd_headers=sc.headers, */
/* dsd_umap=sc.umap, */
/* genes=&glist, */
/* GLMStatOutDsd=GLMStatOut, */
/* GLM_classes=sex medication &pheno_var, */
/* GLM_model=&pheno_var sex age medication, */
/* samplewide=0, */
/* sample_var=sample, */
/* pheno_var=&pheno_var */
/* ); */
/*  */
/* proc print data=tgt(obs=10);run; */
/* proc sort data=tgt;by rownames;run; */
/* data tgt; */
/* set tgt; */
/* status=0; */
/* if &pheno_var="critical" then status=2; */
/* else if &pheno_var="severe" then status=1; */
/* run; */
/*  */
/* proc sql; */
/* create table tgt_sample_level as  */
/* select rownames,sample,&cell_type_var,mean(exp) as exp,sex,medication,status */
/* from tgt */
/* group by rownames,sample,&cell_type_var; */
/*  */
/* proc sort data=tgt_sample_level nodupkeys; */
/* by sample rownames &cell_type_var sex medication exp; */
/* run; */
/* data tgt0; */
/* set tgt; */
/* run; */
/* data tgt; */
/* set tgt_sample_level; */
/* run; */
/* *Age can not be used in the linear model, as healthy control is younger then covid19 patients; */
/* proc sgplot data=tgt; */
/* vbox age/group=&pheno_var; */
/* run; */
/*  */
/* ods output ModelANOVA=ModelANOVA; */
/* proc sort data=tgt;by rownames &cell_type_var status;run; */
/* proc glm data=tgt(where=(&cell_type_var contains 'iliated')); */
/* proc glm data=tgt; */
/* class sex medication; */
/* model exp=sex medication status; */
/* by rownames &cell_type_var; */
/* run; */
/* data ModelANOVA; */
/* set ModelANOVA; */
/* where source="status"; */
/* attrib ProbF format=best32.; */
/* run; */
/* proc print data=ModelANOVA; */
/* var rownames ProbF &cell_type_var; */
/* where HypothesisType=3 and ProbF<0.05 and ProbF>0 and &cell_type_var contains 'iliated'; */
/* where HypothesisType=3 and ProbF<(0.05/32) and ProbF>0; */
/* where HypothesisType=3 and ProbF<0.05 and ProbF>0; */
/* run; */
/*  */
/*  */
/* *Make heatmap; */
/* data dsd4heatmap (keep=rownames &cell_type_var logP probF); */
/* set GLMStatOut; */
/* logP=-log10(probF); */
/* if logP<-log10(0.05/(12*21)) then logp=.; */
/* *if logP<1.3 then logp=.; */
/* if logP>50 then logP=50; */
/* where source="&pheno_var" and  */
/*       &cell_type_var not contains 'Outlier'; */
/* label &cell_type_var="Single cell types" rownames="Genes close rs16831827" */
/* logP="ANOVA -log10(P) among healthy control, severe, and critical COVID-19";       */
/* run; */
/* %ds2csv(data=dsd4heatmap,runmode=b,csvfile='DEG_COVID19_sc4MAP3K19_association_genes.csv'); */
/* %heatmap4longformatdsd( */
/* dsdin=dsd4heatmap, */
/* xvar=rownames, */
/* yvar=&cell_type_var, */
/* colorvar=logP, */
/* fig_height=800, */
/* fig_width=800, */
/* outline_thickness=2 */
/* ); */

%mend;


/*Demo code:;

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
*libname sc "/home/cheng.zhong.shan/data";
%let sc_lib_dir=/home/cheng.zhong.shan/data;
*%let sc_lib_dir=J:\Coorperator_projects\Blood_pressure_GWAS_vs_COVID\Heart_vs_COVID19;
libname sc "&sc_lib_dir";

*Try to get phenotype categories if the sc.umap is already created;
proc sql;
select unique(disease)
from sc.umap;


*This is for heart single cell data set;
%ucsc_sc_analysis_pipeline(
remove_pre_sc_sas_dsds=0,
sc_lib_path=&sc_lib_dir,
umap_http_link=https://cells.ucsc.edu/covid19-cellular-targets/heart/all/UMAP.coords.tsv.gz,
exprMatrix_http_link=https://cells.ucsc.edu/covid19-cellular-targets/heart/all/exprMatrix.tsv.gz,
meta_http_link=https://cells.ucsc.edu/covid19-cellular-targets/heart/all/meta.tsv,
cellid_in_meta_tsv=cellid, 
pheno_var=disease,
ordered_pheno_categories=healthy COVID19,
cell_type_var=cluster,
grpvar4boxplot=sex,
tgt_genes_in_order=SPEG,
rgx4_not_matched_cells_as_others=.,
samplewide=0,
sample_var=,
AllCellsboxplot_width=1000,
AllCellsboxplot_height=300,
umap_width=600,
umap_height=600,
umap_lattice_nrows=1,
AllCellsboxplot_nrows=1,
frqboxplot_height=200,
frqboxplot_width=1000,
frqboxplot_nrows=1,
frqwhere_cnd_for_sgplot=%quote(),
other_glm_classes=,
alt_umap_cell_height=300,
alt_umap_total_width=600,
umap4all_cells_height=600,
umap4all_cells_width=600,
sample_level_exp_analysis=2
);

*cardiomyocyte|vsmc|fib|vas|lym;

*/


/*

*This is for hypertenstion COVID-19 single cell data set;
options mprint mlogic symbolgen;
%ucsc_sc_analysis_pipeline(
remove_pre_sc_sas_dsds=0,
sc_lib_path=/home/cheng.zhong.shan/data,
umap_http_link=https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz,
exprMatrix_http_link=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
meta_http_link=https://cells.ucsc.edu/covid-hypertension/meta.tsv,
cellid_in_meta_tsv=cell, 
pheno_var=severity,
ordered_pheno_categories=control_healthy severe critical,
cell_type_var=cluster,
grpvar4boxplot=,
tgt_genes_in_order=MAP3K19,
rgx4_not_matched_cells_as_others=cilia,
samplewide=0,
sample_var=,
AllCellsboxplot_width=300,
AllCellsboxplot_height=800,
umap_width=1000,
umap_height=400,
umap_lattice_nrows=1,
AllCellsboxplot_nrows=5,
frqboxplot_height=800,
frqboxplot_width=300,
frqboxplot_nrows=2,
frqwhere_cnd_for_sgplot=%quote(),
other_glm_classes=sex
);

*/


