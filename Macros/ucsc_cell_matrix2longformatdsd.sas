%macro ucsc_cell_matrix2longformatdsd(
gzfile_or_url,
dsdout4headers,
dsdout4data
);

%if %eval(%sysfunc(prxmatch(/http.*gz/i,&gzfile_or_url))=1) %then %do;
 *Download exp matrix gz file;
 *In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
 %dwn_http_file(httpfile_url=&gzfile_or_url,outfile=exp.matrix.gz,outdir=%sysfunc(getoption(work)));
 %let file=%sysfunc(getoption(work))/exp.matrix.gz;
%end;
%else %do;
 %if %eval(%sysfunc(prxmatch(/http.*gz/i,&gzfile_or_url))=1) %then %do;
   %let file=&gzfile_or_url;
 %end;
 %else %do;
   %put "Please make sure your input file &gzfile_or_url is gz file!";
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
infile_command=%nrstr(
delimiter='09'x firstobs=1 obs=1 truncover lrecl=100000000;
input gene :$50. @@;
do i=1 to 100000000;
 input colnames @;
 if colnames^="" then output;
 else stop;
end;
drop gene;
)
);
data _null_;
set &dsdout4headers end=eof;
if eof then do;
 call symputx('totnumheaders',left(trim(put(_n_,12.))));
run;

*Get column lengths;
filename inzip zip "&file" gzip;
%get_numeric_table_vars_length(
filename_ref_handle=inzip,
total_num_vars=&totnumheaders,
macro_prefix4NumVarLen=NumVarLen,
firstobs=2,
first_input4charvars=rownames,
macro_prefix4CharVarLen=CharVarLen,
dlm='09'x
);
filename inzip clear;

%ImportFileHeadersFromZIP(
zip=&file,
filename_rgx=.,
obs=max,
sasdsdout=&dsdout4data,
deleteZIP=1,
infile_command=%str(
delimiter='09'x firstobs=2 obs=3 truncover lrecl=100000000;
input rownames :$&CharVarLen1. @@;
do i=1 to 100000000;
 input value @;
 if value^="" then output;
 else stop;
end;
)
);

%mend;
/*Demo:
*https://communities.sas.com/t5/SAS-Procedures/first-row-exceed-32767-lrecl-not-work/td-p/217384

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

options mprint mlogic symbolgen;
%ucsc_cell_matrix2longformatdsd(
gzfile_or_url=https://cells.ucsc.edu/covid-hypertension/exprMatrix.tsv.gz,
dsdout4headers=headers,
dsdout4data=exp
);

*/


 
