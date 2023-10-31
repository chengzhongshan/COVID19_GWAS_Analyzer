%macro import_sc_mtex_meta_umap_data(
umap_file=https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz,
/*local uncompressed or compressed (.gz) umap file or http link for compressed umap gz file*/
meta_file=https://cells.ucsc.edu/covid-hypertension/meta.tsv,
/*meta data for the single cells and samples*/
cell_id_in_meta=cell,
/*need to ensure the column name for cells is cell, otherwise, please the real name
used by the meta_file; this var will be important for merger of meta and umap files*/
exp_matrix_file=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
/*local or remote uncompressed or compressed gz file*/
outdir=%sysfunc(pathname(HOME)), 
/*3 sas data sets will be created and put into the dir:
exp (read matrix with column headers, and the last column is for genesymbol), 
umap (umap coordinates with sample meta data merged), 
headers (column headers for the exp matrix)
*/
target_genes= /*To save space in SAS On Demand for Academics, 
provide genesymbols separated by | without space to focus on specific
genes; prxmatch will be use this list to match records;
So do not add square to contain them!*/
);

%if %sysfunc(prxmatch(/http/,&umap_file)) %then %do;
*Download UMAP gz file;
*%let httpfile_url=https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz;
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%dwn_http_file(httpfile_url=&umap_file,outfile=Seurat_umap.coords.tsv.gz,outdir=%sysfunc(getoption(work)));

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
%end;
%else %do;
%ImportFileHeadersFromZIP(
zip=&umap_file,
filename_rgx=.,
obs=max,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(
obs=max delimiter='09'x truncover;
input seq_ID :$200. x y;)
);

%end;


*Download cell type and other meta info;
%if %sysfunc(prxmatch(/https/,&meta_file)) %then %do;
filename meta url "&meta_file";
%end;
%else %do;
filename meta "&meta_file";
*filename meta url 'https://cells.ucsc.edu/covid-hypertension/meta.tsv';
%end;

proc import datafile=meta dbms=tab out=info replace;
getnames=yes;guessingrows=max;
run;
filename meta clear;

proc sql;
create table UMAP as 
select a.*,b.*
from x as a,
     info as b
where a.seq_ID=b.cell;

*Now download UCSC single cell gene expression data;
*https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz;

*Need to use nrbquote but not str or bquote to mask the filter with quote and square;
%if %length(&target_genes)>0 %then %let extra_cmd4infile=%nrbquote(if prxmatch("/(&target_genes)/i",rownames));
%else %let extra_cmd4infile=;
options notes;
%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=&exp_matrix_file,
dsdout4headers=headers,
dsdout4data=exp,
extra_cmd4infile=&extra_cmd4infile,
guess_numeric_var_length=0
);
/* %abort 255; */
*Note: extra_cmd4infile need to be masked for squares again for str macro;

*perform deseq normalization for single cell expression data;
/*
%deseq_normalization(
dsdin=exp,
read_vars=_numeric_,
dsdout=exp,
readcutoff=3,
cellcutoff=500
);
*/
*Successfully generated normalized single cell expression data;
*Move data into lib sc;
*Please create the data directory;
*%mkdir(dir=%sysfunc(pathname(HOME))/data);

*libname sc "%sysfunc(pathname(HOME))/data";
libname sc "&outdir";
proc datasets nolist;
copy in=work out=sc memtype=data move;
select exp headers umap ;
run;
libname sc clear;

%mend;

/*Demo:;
*options mprint mlogic symbolgen;
%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

%import_sc_mtex_meta_umap_data(
umap_file=https://cells.ucsc.edu/covid-hypertension/Seurat_umap.coords.tsv.gz,
meta_file=https://cells.ucsc.edu/covid-hypertension/meta.tsv,
cell_id_in_meta=cell,
exp_matrix_file=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
outdir=%sysfunc(pathname(HOME)) 
);

*/
