%macro ucsc_cell_matrix2wideformatdsd(
/*Note: this macro can also import large table with 1st column is gene and others for sample exp!*/
gzfile_or_url,/*Can be url for gz or plain text or tsv file; also, it can be a fullpath for these files in local computer*/
dsdout4headers,
dsdout4data,
extra_cmd4infile=,/*It is better to nrbquote it in cases of containing square or dobule/single quotes,
as the macro importfileHeadersFromZIP will use unquote to get back its value!*/
dlm='09'x,
guess_numeric_var_length=1, /*Scan whole file to guess the largest length of numberic var;
if not guess numeric var length, the max length for numeric var will be set as 8.*/
max_cells2import=1000000, /*The maximum number of randomly selected cells to be imported into sas if the parameter randomly_select_cells as 1*/
randomly_select_cells=1, /*Enable the macro to randomly select the total number of cells based on the parameter max_cells2import*/
delete_input_gzfile=1 /*Delete input or downloaded file that represented by the macro var gzfile_or_url*/
);

%if %sysfunc(prxmatch(/http.*gz/i,&gzfile_or_url)) %then %do;
 *Download exp matrix gz file;
 *In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
 %dwn_http_file(httpfile_url=&gzfile_or_url,outfile=exp.matrix.gz,outdir=%sysfunc(getoption(work)));
 %let file=%sysfunc(getoption(work))/exp.matrix.gz;
%end;
%else %do;
 %if %sysfunc(prxmatch(/(.*gz|tsv|txt)/i,&gzfile_or_url)) %then %do;
   %let file=&gzfile_or_url;
 %end;
 %else %do;
   %put "Please make sure your input file &gzfile_or_url is gz, tsv, or text file that is separated by tab!";
   %abort 255;
 %end;
%end;
*Import UMAP gz file into SAS;
%let lengthmax=32767;
*read data records;
*This is not comprehensive;
*If the line length >32767, the colnames would not include all records;
*Ensure the right delimiter used by countc and scan;

*Get column names;
%ImportFileHeadersFromZIP(
zip=&file,
filename_rgx=.,
obs=max,
sasdsdout=&dsdout4headers,
deleteZIP=0,
infile_command=%str(
delimiter=&dlm firstobs=1 obs=1 truncover lrecl=1000000000;
input gene :$50. @@;
do i=1 to 1000000000;
 input colnames :$50. @;
 if colnames^="" then do;
  output;
 end;
 else do;

  stop;
 end;
end;
drop gene;
)
);
%global totcols;
proc sql noprint;
select max(i) into: totcols 
from &dsdout4headers;
%put total number of cols are &totcols;
%let totcols=%sysfunc(trim(&totcols));

*Get column lengths;
*Need to use 7zip in Windows;
%if "&sysscp"="WIN" %then %do;

 %if %sysfunc(prxmatch(/gz/i,&file)) %then %do;
	*Need to use 7zip in Windows;
	*Uncompress gz file;
 *Actionable command: 7z e B1_vs_B2.zscore.txt.gz -y;
	%let _gzfile_=%scan(&file,-1,/\);
	*need to consider [\/\\] for the separator of &zip;
	%let _gzdir_=%sysfunc(prxchange(s/(.*)[\/\\][^\/\\]+/$1/,-1,&file));
	%put your gz file dir is &_gzdir_;
	%put you gz file is &_gzfile_;
	%let filename4dir=%sysfunc(prxchange(s/\.gz//,-1,&_gzfile_));
	*This is to prevent the outdir4file with the same name as the gz file;
	*windows will failed to create the dir if the gz file exists;
	%if %sysfunc(exist(&_gzdir_/&filename4dir)) %then %do;
	%put The dir &filename4dir exists, and we assume the file has been uncompressed!;
	%end;
  %else %do;
 %Run_7Zip(
 Dir=&_gzdir_,
 filename=&_gzfile_,
 Zip_Cmd=e, 
 Extra_Cmd= -y ,
 outdir4file=&filename4dir
 );
	*Use the filename to create a dir to save uncompressed file;
	*Note Run_7Zip will change dir into outdir4file;
 %end;

%let uncmp_gzfile=%sysfunc(prxchange(s/\.gz//,-1,&_gzfile_));
*Use regular expression to match file, as the uncompressed file may have different appendix, such as tsv.gz.tmp;
filename inzip "&_gzdir_/&filename4dir/*";
%end;
%else %do;
   *For plain text or tsv file;
   %let _gzfile_=&file;
   filename inzip "&_gzfile_";
 %end;
  
  %end;


%else %do;
*for linux system;
filename inzip zip "&file" gzip;
%end;

*Turn off notes when there are >10000 columns;
*This is because the line is too long and sas will complain it;
*Even the the line is too long, the first 10000 columns would be enough for;
*guessing the max_len of numeric vars;
%if %eval(&totcols>10000) %then %do;
 *option nonotes; 
%end;

%if &guess_numeric_var_length=1 %then %do;
%get_numeric_table_vars_length(
filename_ref_handle=inzip,
total_num_vars=&totcols,
macro_prefix4NumVarLen=NumVarLen,
firstobs=2,
first_input4charvars=rownames,
macro_prefix4CharVarLen=CharVarLen,
dlm=&dlm,
getmaxlen4allvars=1
);
%end;
%else %do;
%let max_len=8;
%let CharVarLen1=50;
%end;

option notes;
filename inzip clear;

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
*The above was inclued in the macro get_numeric_table_vars_length;

*Read data with specific lengths;
*When using variable length with : and macro var;
*It is vital to add two '.' after the macro var;


%if &totcols<&max_cells2import %then %do;

%ImportFileHeadersFromZIP(
zip=&file,
filename_rgx=.,
obs=max,
sasdsdout=&dsdout4data,
deleteZIP=&delete_input_gzfile,
infile_command=%bquote(
delimiter=&dlm firstobs=2 obs=max truncover lrecl=1000000000;
length V1-V&totcols &max_len.;
input rownames :$&CharVarLen1.. V1-V&totcols;
&extra_cmd4infile;
)
);

%end;
%else %do;
*if &totcols > 1000000, then only get 1000000 random cells;
%put You input matrix file contains &totcols numeric columns, which is more than the threshold of &max_cells2import!;
%put To handle out of disk space in SAS OnDemand for Academics, the macro will randomly select &max_cells2import numeric columns!;
%random_import_cell_mtex(
gzfile=&file,
max_colnum=,/*Default is empty for using all numeric columns in the input gzfile, as the macro will determine it automatically;
This parameter will be used as the larget number to loop the columns to get data from all columns;
if the number is not determined by the macro variable &totcols, provide an enough large number, such as 100 million to cover all columns;*/
totrandom_cols=&max_cells2import,/*Total number of randomly selected cells out of all cells*/
random_seed=2718,
outdsd=&dsdout4data,
rowname_len=&CharVarLen1, /*The length of the 1st rowname length*/
V_max_len=&max_len, /*The length for all numeric cell expression value*/
deletefile=&delete_input_gzfile, /*Delete input gzfile*/
extra_cmd4infile=&extra_cmd4infile
);
);

%end;

/* %abort 255; */

%mend;
/*Demo:
*https://communities.sas.com/t5/SAS-Procedures/first-row-exceed-32767-lrecl-not-work/td-p/217384

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*options mprint mlogic symbolgen;
%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
dsdout4headers=headers,
dsdout4data=exp,
extra_cmd4infile=
);

*check file size, and the dataset exp was compressed from 5Gb to ~1Gb;
proc datasets lib=work;
run;

*Demo2:;
*Apply if for GEO large expression data set;
%let matrix_url=https://ftp.ncbi.nlm.nih.gov/geo/series/GSE215nnn/GSE215865/suppl/GSE215865_rnaseq_logCPM_matrix.csv.gz;
*Updated the sas macro for import large matric table with the 1st column is gene and others are sample expression columns;
%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=&matrix_url,
dsdout4headers=headers,
dsdout4data=exp,
extra_cmd4infile=,
dlm=','
);

*Demo3:;
%debug_macro;
%ucsc_cell_matrix2wideformatdsd(
gzfile_or_url=E:\sas_testing\exprMatrix.tsv\exprMatrix.tsv,
dsdout4headers=headers,
dsdout4data=exp
);

*/


 
