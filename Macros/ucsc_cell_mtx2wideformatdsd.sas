%macro ucsc_cell_mtx2wideformatdsd(
/*This macro can import data from url, downloaded gz file, or even plain files*/
mtx_gzfile_or_url=matrix.mtx.gz,/*Important: Input fullpath or url for these 3 input files*/
feat_gzfile_or_url=features.tsv.gz,
barcode_gzfile_or_url=barcodes.tsv.gz,
dsdout4headers=header,
dsdout4data=exp,
extra_cmd4infile=,
OnSASOnDemand=1,/*if it is true, it will use gzip funciton but not the linux zcat*/
use_zcat=0, /*For HPC Linux system, asign value 1 indicating to use zcat;
The macro will first check whether it is running with SAS OnDemand for Academics,
if it is, it will change back the use_zcat as 0!*/
Readcutoff=0,/*It works with NumOfCells with expression reads greater or equal to this cutoff, i.e., Readcutoff >= 0*/
NumOfCells=0, /*Filter out cells with non-zeor values, i.e., NumOfCells >= 0*/
meancutoff=0, /*Filter out cells with too low expression, i.e., meancutoff >= 0*/
subset_by_genes=,  /*Provide gene symbols to only extract subset data for the dsdout4data;
This would be helpful when the matrix is too large to be imported into SAS*/
max_random_cells2import=1000000, /*If total number of cells larger than this cutoff, 
the macro will randomly select the specificied number of cells;
Note: if provide a cutoff > total number of cells in the matrix file, the macro 
will not randomly select cells but instead choose all cells!*/ 
random_seed=2718 /*random seed for selecting cells if total number of cells > max_random_cells2import*/
);

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
  *Note it is necessary to remove other no ENSG info using prxchange;
  %ImportFileHeadersFromZIP(
  zip=&ftfile,
  filename_rgx=.,
  obs=max,
  sasdsdout=features,
  deleteZIP=0,
  infile_command=%str(
  truncover lrecl=1000;
  input feature :$50.;
  feature=prxchange('s/\W.*//',-1,feature);
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
  select trim(left(put(totbarcodes,8.))) into: totcols
  from dsd4totcolsrows;
  *for symexist function, just provide macro varname without & or quote;
  %if %symexist(totcols) %then %do;
    %put There are &totcols columns in the matrix;
  %end;
  %else %do;
    %put Something is wrong for your input exp matrix, as the 3rd line does not have total rows and cols info;
	%abort 255;
  %end;



************************Important codes to import sparse matrix w/wo filters*****************************;
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
  firstobs=4 obs=max truncover lrecl=1000000000 end=eof;
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
  firstobs=4 obs=max truncover lrecl=1000000000 end=eof;
   retain rowtag V1-V&totcols . xn 0;
   array XX{*} V1-V&totcols;

   input row col exp;

   call symputx('colnum',trim(left(put(col,8.))));
   if  _n_=1 then rowtag=row;
   
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
   if eof then do;
    if (mean(of XX[*]) >= &meancutoff and xn >= &NumOfCells)  then output; 
    stop;
   end;
   drop col row exp xn;
 ) ;

%end;

/* %abort 255;*/

*Randomly select cells if the sparse matrix is too large!;
%if &max_random_cells2import>&totcols %then %do;
  %put We will adjust the macro var max_random_cells2import equal to &totcols; 
  %put as the initial aissigned values for the max_random_cells2import (n=&max_random_cells2import) larger than the total number of cells (n=&totcols);
%end;

%if (&totcols > &max_random_cells2import) %then %do;
 *This procedure will be much faster;
 %put The total number of cells (n=&totcols) is greater than the maximum number of cells allowed to be imported;
 %put We will randomly select the total number of &max_random_cells2import cells for import!;
*Note: it is necessary to use bquote when there are macro pct included in the infile_command;
%ImportFileHeadersFromZIP(
zip=&mtxfile,
filename_rgx=.,
obs=max,
sasdsdout=&dsdout4data,
deleteZIP=0,
infile_command=%bquote(
delimiter=' ' firstobs=4 obs=max truncover;

%if &max_random_cells2import<&totcols %then %do;

if _n_=1 then do;
 array H{&totcols} _temporary_ (1:&totcols);
 array S{&max_random_cells2import} _temporary_ (1:&max_random_cells2import);
 _iorc_=&random_seed;
  call ranperm(_iorc_,of H{*});
  do _si_=1 to &max_random_cells2import;
    S{_si_}=H{_si_};
   end;
end;
input row col exp;
%if %length(&extra_filter_by_genes)>0 %then %do;
 if (&extra_filter_by_genes) and (col in S) then output;
%end;
%else %do;
 if col in S then output;
%end;

%end;

%else %do;

input row col exp;
%if %length(&extra_filter_by_genes)>0 %then %do;
 if (&extra_filter_by_genes)  then output;
%end;

%end;

drop _si_;
)
);

proc transpose data=&dsdout4data out=&dsdout4data(drop=_name_) prefix=V;
var exp;
id col;
by row;
run; 
%VarnamesInDsd(indsd=&dsdout4data,Rgx=V\d+,match_or_not_match=1,outdsd=colnames);
data colnames;set colnames;n=scan(name,1,'V')+0;col_order=_n_;run;
data _Header_;set Header;n=_n_;run;
proc sql;
create table Header(drop=n col_order) as 
select a.*,b.col_order
from _Header_ as a,
        Colnames as b
where a.n=b.n
order by col_order;
*Add rownames to the exp dataset and ensure it is put at the end of table;
proc sql;
create table &dsdout4data(drop=row) as
select a.*,b.feature as rownames
from &dsdout4data as a,
         features as b
where a.row=b.rowtag;
%end;

%else %do;
  *Generate wide format exp matrix from sparse matrix;
  *Which would be very slow!;

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
  /*proc datasets;
  run;
  */
  /*proc print data=&dsdout4data(obs=10);run;
  proc sort data=&dsdout4data;by rowtag;
  proc transpose data=&dsdout4data out=x_trans;
  var V1-V&totcols;
  by rowtag;
  run;
  proc print data=x_trans;
  where col1>0;
  run;
  */


  *Now add the rownames to the dataset;
  *Since there would be >20000 columns, the proc sql procedure will be very slow!;
/*  proc sql;*/
/*  create table &dsdout4data as*/
/*  select a.*,b.feature as rownames*/
/*  from &dsdout4data as a*/
/*  left join*/
/*  features as b*/
/*  on a.rowtag=b.rowtag;*/

  *The export will fail when there are too many vars contributing to the line length > 32767;
  /*proc export data=&dsdout4data outfile="test.txt" dbms=tab replace;
  run;
  */
  *This will work;
  /* filename T 'test.txt'; */
  /* data _null_; */
  /* set &dsdout4data; */
  /* file T lrecl=10000000; */
  /* put (_ALL_)(+0); */
  /* ;;; */
  /* run; */
 %end;

%end;
/*This end matchs with the if on line 90: *For linux system, it is much easier to use zcat to pipe data into the macro;*/

************************The following is prepared for windows but not functional;
/*  */
/* %put The windows version of this function is not completed; */
/* %abort 255; */
/*  */
/* %global totcols; */
/* proc sql noprint; */
/* select max(i) into: totcols */
/* from &dsdout4data; */
/* %put total number of cols are &totcols; */
/* %let totcols=%sysfunc(trim(&totcols)); */
/*  */
/* *Get column lengths; */
/* *Need to use 7zip in Windows; */
/* %if "&sysscp"="WIN" %then %do; */
/* *Need to use 7zip in Windows; */
/* *Uncompress gz file; */
/* *Actionable command: 7z e B1_vs_B2.zscore.txt.gz -y; */
/* %let _gzfile_=%scan(&file,-1,/\); */
/* *need to consider [\/\\] for the separator of &zip; */
/* %let _gzdir_=%sysfunc(prxchange(s/(.*)[\/\\][^\/\\]+/$1/,-1,&file)); */
/* %put your gz file dir is &_gzdir_; */
/* %put you gz file is &_gzfile_; */
/* %let filename4dir=%sysfunc(prxchange(s/\.gz//,-1,&_gzfile_)); */
/* *This is to prevent the outdir4file with the same name as the gz file; */
/* *windows will failed to create the dir if the gz file exists; */
/* %if %sysfunc(exist(&_gzdir_/&filename4dir)) %then %do; */
/* %put The dir &filename4dir exists, and we assume the file has been uncompressed!; */
/* %end; */
/* %else %do; */
/* %Run_7Zip( */
/* Dir=&_gzdir_, */
/* filename=&_gzfile_, */
/* Zip_Cmd=e, */
/* Extra_Cmd= -y , */
/* outdir4file=&filename4dir */
/* ); */
/* *Use the filename to create a dir to save uncompressed file; */
/* *Note Run_7Zip will change dir into outdir4file; */
/* %end; */
/* %let uncmp_gzfile=%sysfunc(prxchange(s/\.gz//,-1,&_gzfile_)); */
/* *Use regular expression to match file, as the uncompressed file may have different appendix, such as tsv.gz.tmp; */
/* filename inzip "&_gzdir_/&filename4dir/*"; */
/* %end; */
/* %else %do; */
/* filename inzip zip "&file" gzip; */
/* %end; */
/*  */
/*  */
/* *Turn off notes when there are >10000 columns; */
/* *This is because the line is too long and sas will complain it; */
/* *Even the the line is too long, the first 10000 columns would be enough for; */
/* *guessing the max_len of numeric vars; */
/* %if %eval(&totcols>10000) %then %do; */
/* option nonotes; */
/* %end; */
/* %get_numeric_table_vars_length( */
/* filename_ref_handle=inzip, */
/* total_num_vars=&totcols, */
/* macro_prefix4NumVarLen=NumVarLen, */
/* firstobs=2, */
/* first_input4charvars=rownames, */
/* macro_prefix4CharVarLen=CharVarLen, */
/* dlm='09'x, */
/* getmaxlen4allvars=1 */
/* ); */
/* option notes; */
/* filename inzip clear; */
/* *a temporary macro for generating length commands; */
/* %macro length_generator; */
/* *This does not work when there are too many vars; */
/* %do xi=1 %to &totcols; */
/*  V&xi &&NumVarLen&xi. */
/* %end; */
/*  */
/* *Get max length, and then use it for all numeric vars; */
/* %global max_len; */
/* %let max_len=&NumVarLen1; */
/* %do i=1 %to &totcols; */
/*    %if %eval(&&NumVarLen&i > &max_len) %then */
/*    %let max_len=&&NumVarLen&i;   */
/* %end; */
/*   %put maximum var length for macro vars (n=&totcols) is &max_len; */
/* %mend; */
/*  */
/* %length_generator; */
/* *The above was inclued in the macro get_numeric_table_vars_length; */
/* *Read data with specific lengths; */
/* *When using variable length with : and macro var; */
/* *It is vital to add two '.' after the macro var; */
/* %ImportFileHeadersFromZIP( */
/* zip=&file, */
/* filename_rgx=., */
/* obs=max, */
/* sasdsdout=&dsdout4data, */
/* deleteZIP=1, */
/* infile_command=%str( */
/* delimiter='09'x firstobs=2 obs=max truncover lrecl=100000000; */
/* length V1-V&totcols &max_len.; */
/* input rownames :$&CharVarLen1.. V1-V&totcols; */
/* &extra_cmd4infile; */
/* ), */
/* use_zcat=0 */
/* ); */

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

%ucsc_cell_mtx2wideformatdsd(
mtx_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\exp.matrix.gz,
feat_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\feature.gz,
barcode_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\barcodes.gz,
dsdout4headers=header,
dsdout4data=exp,
extra_cmd4infile=,
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

%debug_macro;
%ucsc_cell_mtx2wideformatdsd(
mtx_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/matrix.mtx.gz,
feat_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/features.tsv.gz,
barcode_gzfile_or_url=https://cells.ucsc.edu/covid19-toppcell/int-all-cells/barcodes.tsv.gz,
dsdout4headers=header,
dsdout4data=exp,
extra_cmd4infile=,
OnSASOnDemand=1,
use_zcat=0
);

*Just use previously downloaded data;
%debug_macro;
%ucsc_cell_mtx2wideformatdsd(
mtx_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\exp.matrix.gz,
feat_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\feature.gz,
barcode_gzfile_or_url=E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc\barcodes.gz,
dsdout4headers=header,
dsdout4data=exp,
extra_cmd4infile=,
OnSASOnDemand=0,
use_zcat=0,
Readcutoff=0,
NumOfCells=0, 
meancutoff=0, 
subset_by_genes=,
max_random_cells2import=10000000000 
);

libname SC "E:\JAK2_APOBEC3_and_MAP3K4_papers\sc_toppedCells_ucsc";
proc datasets;
copy in=work out=SC move;
select Exp Features Header Dsd4totcolsrows;
run;

*/

