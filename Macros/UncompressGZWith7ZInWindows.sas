%macro UncompressGZWith7ZInWindows(
gzfilepath=,/*fullfilepath for gz file*/
globalvar4finalfile=final_gz_file 
/*Provide a global macro var name to access the uncompressed file later by other macros*/
);

%global &globalvar4finalfile;
*Assign missing value for the global var;
%let &globalvar4finalfile=;

%let file=&gzfilepath;
%if %sysfunc(exist(&file))^=0 %then %do;
  %put No gz file: &file;
  %abort 255;
%end;

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
 %if %direxist("&_gzdir_/&filename4dir") %then %do; 
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
 x dir /B /S "&_gzdir_/&filename4dir" >"&_gzdir_/filelist" ;
data _null_;
infile "&_gzdir_/filelist" lrecl=1000;
input;
call symputx("&globalvar4finalfile",_infile_);
run;
%if %length(&&globalvar4finalfile)=0 %then %do;
    %put Failed to generate the macro var &globalvar4finalfile by uncompressing the file &gzfilepath;
%end;
%end;
 
%else %do; 
  %put This not Windows system, please use zcat or gzip function for Linux system;
  %abort 255;
%end; 
%mend;


/*

%let httpfile_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_AFR_061821.txt.gz;
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%dwn_http_file(httpfile_url=&httpfile_url,outfile=downloaded.gz,outdir=%sysfunc(getoption(work)));

%debug_macro;
%UncompressGZWith7ZInWindows(
gzfilepath=E:\JAK2_New_papers\sc_toppedCells_ucsc\barcodes.gz,
globalvar4finalfile=finalfilepath 
);
%put Final uncompressed file fullpath is here:;
%put &finalfilepath;

*/

