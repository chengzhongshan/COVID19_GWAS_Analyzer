*This SAS script will perform single cell differential expression analysis for a specific query gene;
*options mprint mlogic symbolgen;

%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*Download UMAP gz file;
%let httpfile_url=https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz;
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
filename meta url 'https://cells.ucsc.edu/covid-hypertension/meta.tsv';
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
where a.seq_ID=b.cell;

*Draw scatterplot of UMAP;    
proc sgplot data=UMAP;
scatter x=x y=y/group=cluster;
run;

*Better way is to use datacontrastcolors and datasymbols for sgpanel;
ods graphics on/width=800 height=400;
proc sgpanel data=UMAP;
 *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of;
 *colors with 2nd datasymbols, and the same applied to other datasymbols;
 styleattrs datacontrastcolors=(green gold red black blue grey pink)  
            datasymbols=(circlefilled starfilled triangle diamond square circle) ;
where cluster contains 'Ciliated';
panelby severity/onepanel rows=1 novarname;
scatter x=x y=y/group=cluster;
run;

*Now download UCSC single cell gene expression data;
%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
dsdout4headers=headers,
dsdout4data=exp
);

*perform deseq normalization for single cell expression data;
%deseq_normalization(
dsdin=exp,
read_vars=_numeric_,
dsdout=exp,
readcutoff=3,
cellcutoff=500
);
*Successfully generated normalized single cell expression data;
*Move data into lib sc;
*Please create the data directory;
*%mkdir(dir=%sysfunc(pathname(HOME))/data);

libname sc "%sysfunc(pathname(HOME))/data";
proc datasets nolist;
copy in=work out=sc memtype=data move;
select exp headers umap ;
run;
libname sc clear;

*****************************run analysis here for previously saved single cell data****************************************;
*options mprint mlogic symbolgen;
%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname sc "%sysfunc(pathname(HOME))/data";

ods graphics on/width=1200 height=800;
proc sgplot data=sc.UMAP;
scatter x=x y=y/group=cluster;
label x="UMAP_1" y="UMAP_2";
run;
*Better way is to use datacontrastcolors and datasymbols for sgpanel;
*Only plot 20% cells;
%Sampling(indsd=sc.UMAP,n=17634,nperm=1,dsdout=sub_umap);
data g;
length severity $20.;
input severity $ y;
cards;
control_healthy 1
severe 2
critical 3
;
%mkfmt4grpsindsd(
targetdsd=sub_umap,
grpvarintarget=severity,
name4newfmtvar=new_severity,
fmtdsd=g,
grpvarinfmtdsd=severity,
byvarinfmtdsd=y,
finaloutdsd=sub_map_fmted
);

data sub_map_fmted;
set sub_map_fmted;
if prxmatch('/iliated/',cluster) then do;
cluster=lowcase(cluster);
end;
run;
proc print data=sub_map_fmted(obs=10);run;

******************add group means of x and y for labeling;
proc sql;
create table sub_map_fmted as
select a.*, mean(x) as x_,mean(y) as y_
from sub_map_fmted as a
group by cluster, severity
order by cluster, severity;
data sub_map_fmted;
set sub_map_fmted;
if not first.cluster and not first.severity then do;
  x_=.;y_=.;
end;
by cluster severity;
run;


/* ods graphics on/width=1200 height=600; */
ods graphics on/width=600 height=1600;
proc sgpanel data=sub_map_fmted;
/* where cluster not in ('Outlier' 'Outlier2') ; */
where cluster not in ('Outlier' 'Outlier2') and cluster contains 'iliated';
 *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of;
 *colors with 2nd datasymbols, and the same applied to other datasymbols;
/*  styleattrs datacontrastcolors=(green dardyellow gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle); */
 styleattrs datacontrastcolors=(green darkgreen blueviolet lightcoral bio bippk gold vlipb vlib blueviolet lightpink lightsalmon)
            datasymbols=(circlefilled starfilled triangle diamond square circle);
/* where cluster contains 'Ciliated'; */
panelby new_severity/onepanel rows=3 novarname;
scatter x=x y=y/group=cluster markerattrs=(size=3);
text x=x_ y=y_ text=cluster;
label x="UMAP_1" y="UMAP_2";
run;


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
boxplot_width=200,
boxplot_height=800,
umap_width=400,
umap_height=800,
umap_lattice_nrows=3,
boxplot_nrows=4,
where_cnd4sgplot=%quote(cluster contains %'iliated%')
);

/* %sc_scatter4gene( */
/* dsd=sc.exp, */
/* dsd_headers=sc.headers, */
/* dsd_umap=sc.umap, */
/* gene=&gene, */
/* pheno_var=severity, */
/* pheno_categories=control_healthy severe critical */
/* samplewide=0, */
/* sample_var=, */
/* boxplot_width=1200, */
/* boxplot_height=1200, */
/* boxplot_nrows=3, */
/* where_cnd4sgplot=%quote(cluster contains %'iliated%') */
/* ); */

/* proc sort data=tgt;by cluster; */
/* ods trace on; */
/* ods select none; */
/* ods output ModelANOVA=ModelANOVA4&gene; */
/* proc glm data=tgt; */
/* class sex medication severity; */
/* model exp=severity sex age medication/ss3; */
/* by cluster; */
/* run; */
/* ods trace off; */
/* ods select all; */
/* data ModelANOVA4&gene; */
/* set ModelANOVA4&gene; */
/* keep cluster source df ss ms fvale probF; */
/* attrib probF format=best12.; */
/* run; */

*output these data for further analysis;
/* proc export data=tgt outfile="%sysfunc(pathname(HOME))/data/&gene..sc.exp.txt" dbms=tab;run; */
/* data single_gene_&gene; */
/* set tgt; */
/* run; */

/* %sc_scatter4genebygrp( */
/* dsd=sc.exp, */
/* dsd_headers=sc.headers, */
/* dsd_umap=sc.umap, */
/* gene=&gene, */
/* pheno_var=severity, */
/* pheno_categories=control_healthy severe critical, */
/* grpvar4boxplot=sex, */
/* samplewide=0, */
/* sample_var=); */

%mend;

%sc_visulization4gene(gene=MAP3K19);


*Make sure use the data set new__tgt_dsd_ generated by the macro sc_scatter4gene;
%umap_with_axes_restriction(
dsdin=new__tgt_dsd_,
umap_width=1000,
umap_height=300,
lattice_or_not=0,
raxis_max=20000,
raxis_min=0,
caxis_max=,
caxis_min=45000);
*same the data set for later usage;
proc datasets nolist;
copy in=work out=sc memtype=data move;
select new__tgt_dsd_;
run;

****************************Important codes to make boxplot and perform GLM analysis********************************;
*****************************run analysis here for previously saved data****************************************;
*options mprint mlogic symbolgen;
%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname sc "%sysfunc(pathname(HOME))/data";

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
proc print data=new__tgt_dsd_(obs=10);%print_nicer;run;
*Use the dataset tgt generated by above to run the macro;
data tgt;
length cell_type $50.;
set new__tgt_dsd_;
cell_type="Other";
if prxmatch('/iliated/',Cluster) then cell_type=Cluster;
if age>60 then old='Yes';
else Old='No';
run;
proc sql;
select unique(cell_type) 
from tgt;
/* %debug_macro; */
*Get percent of different cells;
*Note: we use the exp_cutoff=-1;
*This will calculate the percents of different cells within each pheno group;
*percent=cells/total_cells_in_a_pheno_grp;
*Note: the macro also perform gene expression differential expression analysis!;
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
other_glm_classes=sex medication Old CAD CVD hypertension,
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
other_glm_classes=sex medication Old CAD CVD hypertension,
aggre_sc_glm_pdiff_dsd=all_sc
);
