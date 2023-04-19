%macro ucsc_cell_matrix2wideformatdsd(
gzfile_or_url,
dsdout4headers,
dsdout4data,
extra_cmd4infile=
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
infile_command=%str(
delimiter='09'x firstobs=1 obs=1 truncover lrecl=100000000;
input gene :$50. @@;
do i=1 to 100000000;
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
filename inzip zip "&file" gzip;
%end;

*Turn off notes when there are >10000 columns;
*This is because the line is too long and sas will complain it;
*Even the the line is too long, the first 10000 columns would be enough for;
*guessing the max_len of numeric vars;
%if %eval(&totcols>10000) %then %do;
option nonotes;
%end;

%get_numeric_table_vars_length(
filename_ref_handle=inzip,
total_num_vars=&totcols,
macro_prefix4NumVarLen=NumVarLen,
firstobs=2,
first_input4charvars=rownames,
macro_prefix4CharVarLen=CharVarLen,
dlm='09'x,
getmaxlen4allvars=1
);
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
%ImportFileHeadersFromZIP(
zip=&file,
filename_rgx=.,
obs=max,
sasdsdout=&dsdout4data,
deleteZIP=1,
infile_command=%str(
delimiter='09'x firstobs=2 obs=max truncover lrecl=100000000;
length V1-V&totcols &max_len.;
input rownames :$&CharVarLen1.. V1-V&totcols;
&extra_cmd4infile;
)
);

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


*/


 
