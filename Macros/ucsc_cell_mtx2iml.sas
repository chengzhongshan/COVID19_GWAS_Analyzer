/*The issue for this macro is that the two parameters startlinenum and endlinenum may 
lead to the read of partial data for a specific feature, which means the records of the
feature may be splitted into two sections and included in two blocks*/
%macro ucsc_cell_mtx2iml(
/*This macro can import data from url, downloaded gz file, or even plain files*/
mtx_gzfile_or_url=matrix.mtx.gz,/*Important: Input fullpath or url for these 3 input files*/
feat_gzfile_or_url=features.tsv.gz,
barcode_gzfile_or_url=barcodes.tsv.gz,
dsdout4headers=header,
dsdout4data=exp,
startlinenum=4,/*First record that is not the header or other annotaitons in the mtx file*/
endlinenum=5000,/*The line position number to stop the reading of data;
For testing, set it as 5000; please enlarge it for real large dataset;
To prevent SAS out of space in SAS OnDemand for Academics, it will read 5000000 records;
You can change the startlinenum by a step of 5,000,000 and update the endlinenum accordingly*/
OnSASOnDemand=1,/*if it is true, it will use gzip funciton but not the linux zcat*/
use_zcat=0, /*For HPC Linux system, asign value 1 indicating to use zcat;
The macro will first check whether it is running with SAS OnDemand for Academics,
if it is, it will change back the use_zcat as 0!*/
Readcutoff=3,/*It works with NumOfCells with expression reads greater or equal to this cutoff, i.e., Readcutoff >= 0*/
NumOfCells=500, /*Filter out cells with non-zeor values, i.e., NumOfCells >= 0*/
meancutoff=0.001, /*Filter out cells with too low expression, i.e., meancutoff >= 0*/
subset_by_genes=  /*Provide gene symbols to only extract subset data for the dsdout4data;
This would be helpful when the matrix is too large to be imported into SAS*/
);

*This will let the macro only read records not passed this restricted record line number;
%if &endlinenum eq %then %let endlinenum=max;
*Note: the endlinenum will be adjusted later if it is larger than the total number of records in the file;


%if &OnSASOnDemand=1 or "&sysscp"="WIN" %then %let use_zcat=0;

%let ftfile=&feat_gzfile_or_url;
%if %eval(%sysfunc(prxmatch(/http.*gz/i,&feat_gzfile_or_url))=1) %then %do;
*Download feature gz file for the rownames;
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%if %FileOrDirExist(%sysfunc(getoption(work))/feature.gz)=0 %then %do;
%dwn_http_file(httpfile_url=&feat_gzfile_or_url,outfile=feature.gz,outdir=%sysfunc(getoption(work)));
%end;

%let ftfile=%sysfunc(getoption(work))/feature.gz;

%if "&sysscp"="WIN" %then %do;
%UncompressGZWith7ZInWindows(
gzfilepath=&ftfile,
globalvar4finalfile=finalfilepath 
);
%put Final uncompressed file fullpath is here:;
%put &finalfilepath;
%let ftfile=&finalfilepath;
%end;

%end;

%let barfile=&barcode_gzfile_or_url;
%if %eval(%sysfunc(prxmatch(/http.*gz/i,&barcode_gzfile_or_url))=1) %then %do;
*Download barcode gz file for the column names;
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%if %FileOrDirExist(%sysfunc(getoption(work))/barcodes.gz)=0 %then %do;
%dwn_http_file(httpfile_url=&barcode_gzfile_or_url,outfile=barcodes.gz,outdir=%sysfunc(getoption(work)));
%end;
%let barfile=%sysfunc(getoption(work))/barcodes.gz;

%if "&sysscp"="WIN" %then %do;
%UncompressGZWith7ZInWindows(
gzfilepath=&barfile,
globalvar4finalfile=finalfilepath 
);
%put Final uncompressed file fullpath is here:;
%put &finalfilepath;
%let barfile=&finalfilepath;
%end;

%end;

%let mtxfile=&mtx_gzfile_or_url;
%if %eval(%sysfunc(prxmatch(/http.*gz/i,&mtx_gzfile_or_url))=1) %then %do;
*Download exp matrix gz file;
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%if %FileOrDirExist(%sysfunc(getoption(work))/exp.matrix.gz)=0 %then %do;
%dwn_http_file(httpfile_url=&mtx_gzfile_or_url,outfile=exp.matrix.gz,outdir=%sysfunc(getoption(work)));
%end;
%let mtxfile=%sysfunc(getoption(work))/exp.matrix.gz;

%if "&sysscp"="WIN" %then %do;
%UncompressGZWith7ZInWindows(
gzfilepath=&mtxfile,
globalvar4finalfile=finalfilepath 
);
%put Final uncompressed file fullpath is here:;
%put &finalfilepath;
%let mtxfile=&finalfilepath;
%end;

%end;

*For linux system, it is much easier to use zcat to pipe data into the macro;
%if %sysevalf(&use_zcat=1 or &OnSASOnDemand=1 or "&sysscp"="WIN") %then %do;

  *Get rownames (features) for the sparse long format expression matrix;
  %ImportFileHeadersFromZIP(
  zip=&ftfile,
  filename_rgx=.,
  obs=max,
  sasdsdout=features,
  deleteZIP=0,
  infile_command=%str(
  truncover lrecl=1000;
  input feature :$50.;
  rowtag=_n_;
  ),
  use_zcat=&use_zcat
  );
*Get rowtags for subsetting large exp matrix;
 %if %length(&subset_by_genes)>0 %then %do;
%QueryGTEx4GeneID(
geneids=&subset_by_genes,
genomeBuild=hg38,
outdsd=gene_info
);
data gene_info;
set gene_info;
keep gencodeid genesymbol;
gencodeid=prxchange('s/\.\d+//',1,gencodeid);
run;
proc sql;
create table features_tgt as
select a.*,b.*
from gene_info as a, features as b
where a.gencodeid=b.feature;
*save these rawtags into a macro var;
proc sql noprint;
select rowtag into: rownums separated by ' '
from features_tgt;
select max(rowtag) into: largest_rownum
from features_tgt;
select min(rowtag) into: smallest_rownum
from features_tgt;

%end;

  *Get column names for the sparse long format expression matrix;
  %ImportFileHeadersFromZIP(
  zip=&barfile,
  filename_rgx=.,
  obs=max,
  sasdsdout=&dsdout4headers,
  deleteZIP=0,
  infile_command=%str(
   truncover lrecl=1000;
  input barcodes :$200.;
  ),
  use_zcat=&use_zcat
  );

  *Get total number of columns in the sparse long format expression matrix;
  %ImportFileHeadersFromZIP(
  zip=&mtxfile,
  filename_rgx=.,
  obs=max,
  sasdsdout=dsd4totcolsrows,
  deleteZIP=0,
  infile_command=%str(
  firstobs=3 obs=3 truncover lrecl=1000;
  input totfeatures totbarcodes totrecords;
  ),
  use_zcat=&use_zcat
  );
  /*proc print;run;*/
  proc sql noprint;
  select trim(left(put(totbarcodes,8.))),trim(left(put(totrecords,8.)))
   into: totcols, : totrcds
  from dsd4totcolsrows;
  *for symexist function, just provide macro varname without & or quote;
  %if %symexist(totcols) %then %do;
    %put There are &totcols columns in the matrix, and in total &totrcds records with non-zeros;
    %if "&endlinenum"="max" or %sysevalf(&endlinenum>&totrcds) %then %do;
      %let endlinenum=&totrcds;
      %put The total readable lines is adjusted as &endlinenum, since your input endlinenum (&endlinenum) is gt the total records (&totrcds);
    %end;
  %end;
  %else %do;
    %put Something is wrong for your input exp matrix, as the 3rd line does not have total rows and cols info;
	%abort 255;
  %end;


%let extra_filter_by_genes=;
%if %length(&subset_by_genes)>0 %then %do;
     %do ti=1 %to %ntokens(&rownums);
	    %let num=%scan(&rownums,&ti);
        %let extra_filter_by_genes=%str(&extra_filter_by_genes row=&num);
		%if &ti<%ntokens(&rownums) %then %do;
         %let extra_filter_by_genes=%str(&extra_filter_by_genes %nrbquote(or));
		%end;
	 %end;
 
 %put extra_filter_by_genes are:;
 %put &extra_filter_by_genes;

%let infile_cmd=%str(
  firstobs=4 obs=max truncover lrecl=100000000 end=eof;
   retain rowtag V1-V&totcols . xn 0;
   array XX{*} V1-V&totcols;

   input row col exp;

   if row>&largest_rownum then do;
    if (mean(of XX[*]) >= &meancutoff and xn >= &NumOfCells)  then output; 
    stop;
   end;

   call symputx('colnum',trim(left(put(col,8.))));
   if  row=&smallest_rownum then rowtag=row;
   
   if (&extra_filter_by_genes) then do;
    XX{symget('colnum')}=exp;
   if exp>&Readcutoff then xn=xn+1;

   if rowtag^=row then do;
     XX{symget('colnum')}=.;
     if (mean(of XX[*]) >= &meancutoff and xn >= &NumOfCells)  then output;
     xn=0;
	 rowtag=row;
     retain V1-V&totcols . xn 0;
/*Note: stdize needs to have a non-missing value as input*/
/*	 call stdize('mult=',0,of XX[*]);*/
     call missing(of XX[*]);
     XX{symget('colnum')}=exp;
   end;
 
   end;

   drop col row exp xn;
 ) ;

 %end;

%else %do;
 *Optimized infile cmd for importing sparse expression matrix;
 *It is possible to filter these records based on median expression and total number of cells;
 *The following codes will let SAS run forever, mainly due to use several rounds of large loops;
 *For learning purpose, I keep it here for comparison with latter optimized codes;
/*%let infile_cmd=%str(*/
/*  firstobs=4 obs=max truncover lrecl=100000000 end=eof;*/
/*   retain rowtag V1-V&totcols 0;*/
/*   array XX{*} V1-V&totcols;*/
/**/
/*   input row col exp;*/
/**/
/*   call symputx('colnum',trim(left(put(col,8.))));*/
/*   if _n_=1 then rowtag=row;*/
/*   */
/*   do vi=1 to dim(XX);*/
/*    if vi=symget('colnum') then XX{vi}=exp;*/
/*   end;*/
/*  */
/*   if rowtag^=row then do;*/
/*   */
/*     xn=0;*/
/*     do xi=1 to dim(XX);*/
/*      if XX{xi}>&Readcutoff then xn=xn+1;*/
/*     end;*/
/*     if mean(of XX[*]) > &meancutoff and xn > &NumOfCells then output;*/
/*    */
/*     do vi=1 to dim(XX);*/
/*       XX{vi}=0;*/
/*     end;  */
/*     rowtag=row;*/
/*     do vi=1 to dim(XX);*/
/*       if vi=symget('colnum') then XX{vi}=exp;*/
/*     end;*/
/*   end;*/
/*   */
/*   if eof then output;*/
/*   */
/*   drop col row exp xi xn;*/
/* ) ;*/

%let infile_cmd=%str(
  firstobs=&startlinenum obs=&endlinenum truncover lrecl=100000000;
   retain rowtag V1-V&totcols . xn 0;
   array XX{*} V1-V&totcols;

   input row col exp;

   call symputx('colnum',trim(left(put(col,8.))));
   if  _n_=&startlinenum then rowtag=row;
   
   XX{symget('colnum')}=exp;
   if exp>=&Readcutoff then xn=xn+1;

   if rowtag^=row then do;
     XX{symget('colnum')}=.;
     if (mean(of XX[*]) >= &meancutoff and xn >= &NumOfCells)  then output;
     xn=0;
	 rowtag=row;
     retain V1-V&totcols . xn 0;
/*Note: stdize needs to have a non-missing value as input*/
/*	 call stdize('mult=',0,of XX[*]);*/
     call missing(of XX[*]);
     XX{symget('colnum')}=exp;
   end;
   if _n_=&endlinenum then do;
    if (mean(of XX[*]) >= &meancutoff and xn >= &NumOfCells)  then output; 
    stop;
   end;
   drop col row exp xn _n_;
 ) ;

%end;

/* %abort 255;*/

/*%let extra_filter_by_genes=;*/
/**Even after using %nrbquote, It is still important to add %str again to escape special characters in SAS here;*/
/*/*%let extra_filter_by_genes=%str(&extra_filter_by_genes  %nrbquote(if %());*/*/
/*%if %length(&largest_rownum)>0 %then %do;*/
/*	%let extra_filter_by_genes=%str(&extra_filter_by_genes  %nrbquote(if %());*/
/*     %do ti=1 %to %ntokens(&rownums);*/
/*	    %let num=%scan(&rownums,&ti);*/
/*        %let extra_filter_by_genes=%str(&extra_filter_by_genes row^=&num);*/
/*		%if &ti<%ntokens(&rownums) %then %do;*/
/*         %let extra_filter_by_genes=%str(&extra_filter_by_genes %nrbquote(and));*/
/*		%end;*/
/*	 %end;*/
/*  %end;*/
/* %let extra_filter_by_genes=%str(&extra_filter_by_genes  %nrbquote(%) then delete;) if row>&largest_rownum then stop;);   */
/* %put extra_filter_by_genes are:;*/
/* %put &extra_filter_by_genes;*/

  *Generate wide format exp matrix from sparse matrix;
  %ImportFileHeadersFromZIP(
  zip=&mtxfile,
  filename_rgx=.,
  obs=max,
  sasdsdout=&dsdout4data,
  deleteZIP=0,
  infile_command=%str(
&infile_cmd 
&extra_filter_by_genes
),
  use_zcat=&use_zcat
  );


%end;


%mend;
/*Demo:
*https://communities.sas.com/t5/SAS-Procedures/first-row-exceed-32767-lrecl-not-work/td-p/217384
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
*/

/*
*options mprint mlogic symbolgen;
%include "%sysfunc(pathname(HOME))/Macros/importallmacros_ue.sas";
%importallmacros_ue;

*%importallmacros(macrodir=\\192.168.1.100\F_Win\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros);

*The input files can be gz, url, or plain files;

%ucsc_cell_mtx2iml(
mtx_gzfile_or_url=E:/JAK2_New_papers/sc_toppedCells_ucsc/exp.matrix.gz,
feat_gzfile_or_url=E:/JAK2_New_papers/sc_toppedCells_ucsc/feature.gz,
barcode_gzfile_or_url=E:/JAK2_New_papers/sc_toppedCells_ucsc/barcodes.gz,
dsdout4headers=header,
dsdout4data=exp,
endlinenum=,
OnSASOnDemand=1,
use_zcat=0,
Readcutoff=1,
NumOfCells=1, 
meancutoff=0, 
subset_by_genes=JAK2
);
*subset_by_genes=ZNF337 NOV ;
proc print data=exp(obs=100);
var V1-V10 rowtag;
run;

proc transpose data=exp (drop=rowtag) out=x;
var _numeric_;
run;
proc sgplot data=x(where=(col1>0));
histogram col1/scale=count;
run;

*proc contents data=exp;
*run;

*****************************************************************************;
%debug_macro;

proc iml;
submit;
%ucsc_cell_mtx2iml(
mtx_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/matrix.mtx.gz,
feat_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/features.tsv.gz,
barcode_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/barcodes.tsv.gz,
dsdout4headers=header,
dsdout4data=exp,
startlinenum=4,
endlinenum=10000000,
OnSASOnDemand=1,
use_zcat=0
);
endsubmit;
use exp var _num_;
read all into iml_exp;
close exp;
submit;
proc sql;
drop table exp;
quit;
endsubmit;

t=iml_exp[,1:10];
*store iml_exp;
show storage;
*free iml_exp;


submit;
%ucsc_cell_mtx2iml(
mtx_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/matrix.mtx.gz,
feat_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/features.tsv.gz,
barcode_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/barcodes.tsv.gz,
dsdout4headers=header,
dsdout4data=exp1,
startlinenum=10000001,
endlinenum=20000000,
OnSASOnDemand=1,
use_zcat=0
);
endsubmit;
use exp1 var _num_;
read all into iml_exp1;
close exp1;
submit;
proc sql;
drop table exp1;
quit;
endsubmit;

t=iml_exp1[,1:10];
show storage;
*load iml_exp;
iml_exp_com=iml_exp//iml_exp1;
free iml_exp1 iml_exp;
store iml_exp_com;

t=iml_exp_com[,1:10];
print t;




*Just use previously downloaded data;
%debug_macro;
%ucsc_cell_mtx2iml(
mtx_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\exp.matrix.gz,
feat_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\feature.gz,
barcode_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\barcodes.gz,
dsdout4headers=header,
dsdout4data=exp,
endlinenum=,
OnSASOnDemand=0,
use_zcat=0,
Readcutoff=3,
NumOfCells=500, 
meancutoff=0, 
subset_by_genes= 
);



*/

