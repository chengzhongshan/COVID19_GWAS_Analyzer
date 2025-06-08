/*Note: this macro is only able to import HGI GWAS release 7;*/
%macro ImportHGICovidGWASFromHGI_R7(
zip,
filename_rgx,
sasdsdout,
deleteZIP,
for_subpop=0 /*R7 GWAS for ALL and sub-populations are in different format*/
);
%local nfiles txtfilenames txtfilename;

/*CHR POS REF ALT SNP 
all_meta_N all_inv_var_meta_beta 
all_inv_var_meta_sebeta all_inv_var_meta_p 
all_inv_var_meta_cases all_inv_var_meta_controls 
all_inv_var_meta_effective all_inv_var_het_p 
all_meta_AF rsid b38_chr b38_pos b38_ref b38_alt liftover_info;*/
*need to have: chr pos rsid p SE BETA AF het_p ref alt;
%if &for_subpop=1 %then %do;
%let infile_command=%str(
input 
CHR
POS :12. 
REF :$1. 
ALT :$1. 
SNPID :$15. 
all_meta_N 
beta :12. 
se :12. 
p :12. 
all_inv_var_meta_cases :12. 
all_inv_var_meta_controls :12. 
all_inv_var_meta_effective :12. 
het_p 
AF 
rsid :$15.
b38_chr 
b38_pos :8.
b38_ref :$1.
b38_alt :$1.
liftover_info $1.
);
%end;

%else %do;
%let infile_command=%str(
input 
CHR 
POS 	:12.
REF 	:$1.
ALT 	:$1.
SNP 	:$15.
all_meta_N 
beta 
se
p
cases
controls
effective
het_p
lmso_inv_var_beta
lmso_inv_var_se
lmso_inv_var_pval
AF
rsid  :$15.
b38_chr 
b38_pos :12.
b38_ref  :$1.
b38_alt  :$1.
liftover_info $1. 
);

%end;
/*
Column 	Value 	ord
#CHR 	1 	1
POS 	721371 	2
REF 	G 	3
ALT 	A 	4
SNP 	1:785991:G:A 	5
all_meta_N 	2 	6
all_inv_var_meta_beta 	-5.6679e-01 	7
all_inv_var_meta_sebeta 	3.6910e-01 	8
all_inv_var_meta_p 	1.2464e-01 	9
all_inv_var_meta_cases 	1447 	10
all_inv_var_meta_controls 	98541 	11
all_inv_var_meta_effective 	1391 	12
all_inv_var_het_p 	4.8951e-01 	13
all_meta_AF 	5.855e-03 	14
rsid 	rs539194939 	15
b38_chr 	1 	16
b38_pos 	785991 	17
b38_ref 	G 	18
b38_alt 	A 	19
liftover_info 	. 	20
*/

/* %let infile_command=%str( */
/* informat	chr	$5.; */
/* informat	pos	best32.; */
/* informat	REF	$1.; */
/* informat	ALT	$2.; */
/* informat	SNPID	$30.; */
/* informat	all_meta_N	best12.; */
/* informat	beta	best12.; */
/* informat	se	best12.; */
/* informat	p	best12.; */
/* informat	meta_cases	best12.; */
/* informat	meta_controls	best12.; */
/* informat	meta_effective	best12.; */
/* informat	het_p	best12.; */
/* informat all_meta_sample_N best12.; */
/* informat	AF	best12.; */
/* informat	rsid	$15.; */
/* informat	hg38_chr	$5.; */
/* informat	hg38_pos	best32.; */
/* informat	REF1	$1.; */
/* informat	ALT2	$1.; */
/*  */
/* format	chr	$5.; */
/* format	pos	best32.; */
/* format	REF	$1.; */
/* format	ALT	$2.; */
/* format	SNPID	$30.; */
/* format	all_meta_N	best12.; */
/* format	beta	best12.; */
/* format	se	best12.; */
/* format	p	best12.; */
/* format	meta_cases	best12.; */
/* format	meta_controls	best12.; */
/* format	meta_effective	best12.; */
/* format	het_p	best12.; */
/* format all_meta_sample_N best12.; */
/* format	AF	best12.; */
/* format	rsid	$15.; */
/* format	hg38_chr	$5.; */
/* format	hg38_pos	best32.; */
/* format	REF1	$1.; */
/* format	ALT2	$1.; */
/*  */
/*  */
/* input CHR $ POS REF $ ALT $ SNPID $ all_meta_N beta se p meta_case meta_controls meta_effective  */
/*       het_p AF rsid $ hg38_chr $ hg38_pos REF $ ALT2 $; */
/* input CHR $ POS REF $ ALT $ SNPID $ all_meta_N beta se p  */
/*       het_p all_meta_sample_N AF rsid $; */
/* ); */


options compress=yes;
%local gzip_tag;
/*do not quote the keyword gz for index function*/
%if %index(&zip,gz) %then %do;
	%let gzip_tag=gzip;
%end;
%else %do;
    %let gzip_tag=;
%end;

%if &filename_rgx eq %then %do;
   %let filename_rgx=txt;
%end;

%if &sasdsdout eq %then %do;
  %let sasdsdout=txtdsd;
%end;

%if &gzip_tag ne %then %do;
%let fname=%sysfunc(prxchange(s/(.*\/|\.zip|\.gz|\.tgz)//i,-1,&zip));
/* filename target "%sysfunc(getoption(work))/&fname"; */
/*gzip parameter is only available in latest SAS9.4M5*/

/*filename fromzip ZIP "&zip" GZIP;*/

/*%if "&sysscp"="WIN" %then %do;*/
/*	*Need to use 7zip in Windows;*/
/*	*Uncompress gz file;*/
/* *Actionable command: 7z e B1_vs_B2.zscore.txt.gz -y;*/
/*	%let _gzfile_=%scan(&zip,-1,/\);*/
/*	*need to consider [\/\\] for the separator of &zip;*/
/*	%let _gzdir_=%sysfunc(prxchange(s/(.*)[\/\\][^\/\\]+/$1/,-1,&zip));*/
/*	*Need to confirm whether the _gzdir_ is parsed correctly;*/
/*	*When the &zip var only contains relative path without '.' at the beginning of the dir string;*/
/*	*The prxchange function can not generate right dir;*/
/*	%if %direxist(&_gzdir_) %then %do;*/
/*	 %put your gz file dir is &_gzdir_, which exists;*/
/*	%end;*/
/*	%else %do;*/
/*		%put your gz file dir is &_gzdir_, but which does not exist;*/
/*		%abort 255;*/
/*	%end;*/
/**/
/**/
/*	%put you gz file is &_gzfile_;*/
/*	%let filename4dir=%sysfunc(prxchange(s/(.bgz|.tgz|gz)//i,-1,&_gzfile_));*/
/*	*This is to prevent the outdir4file with the same name as the gz file;*/
/*	*windows will failed to create the dir if the gz file exists;*/
/*	%if %sysfunc(exist(&_gzdir_/&filename4dir)) %then %do;*/
/*	%put The dir &filename4dir exists, and we assume the file has been uncompressed!;*/
/*	%end;*/
/*	%else %do;*/
/* %Run_7Zip(*/
/* Dir=&_gzdir_,*/
/* filename=&_gzfile_,*/
/* Zip_Cmd=e, */
/* Extra_Cmd= -y ,*/
/* outdir4file=&filename4dir*/
/* );*/
/*	*Use the filename to create a dir to save uncompressed file;*/
/*	*Note Run_7Zip will change dir into outdir4file;*/
/*	%end;*/
/**/
/*	%let uncmp_gzfile=%sysfunc(prxchange(s/\.gz//,-1,&_gzfile_));*/
/*	*Use regular expression to match file, as the uncompressed file may have different appendix, such as tsv.gz.tmp;*/
/*	filename fromzip "&_gzdir_/&filename4dir/*";*/
/*%end;*/
/**/
/*%else %do;*/
/*  filename fromzip ZIP "&zip" GZIP;*/
/*%end;*/
*The ahove has been put into a sas macro;

%make_gz_fileref(
zip=&zip,/*full path for the gz file*/
outgzfileref=fromzip /*A fileref for the uncompressed zip file*/
);

/*end for the new codes working in WIN for the part: filename fromzip ZIP "&zip" GZIP;*/

data &sasdsdout (keep=chr pos rsid p SE BETA AF het_p ref alt); 
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile fromzip delimiter='09'x missover dsd firstobs=2;
&infile_command;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
if rsid="NA" then rsid=SNPID;
run;

/* data _null_;    */
/*    infile fromzip; */
/*    file target; */
/*    input; */
/*    put _infile_ ; */
/* run; */
/*  */
/* just get top 10000 records for debugging */
/* options obs=10000; */
/* proc import datafile=target dbms=tab out=&sasdsdout replace; */
/* &extra_proc_import_codes; */
/* run; */
/* reset the max number of importing */
/* options obs=max; */

%end;
%else %do;
/* identify a temp folder in the WORK directory */
%GetZIPContents(zip=&zip,dsdout=contents);

proc sql noprint;
select memname into: txtfilenames separated by " "
from contents
where prxmatch("/&filename_rgx/i",memname);

select dirname into: txtdirs separated by " "
from contents
where prxmatch("/&filename_rgx/i",memname);

%let nfiles=%eval(%sysfunc(countc(&txtfilenames,%str( )))+1);

%do fi=1 %to &nfiles;
%let txtfilename=%scan(&txtfilenames,&fi,%str( ));
%let txtdir=%scan(&txtdirs,&fi,%str( ));

/* filename txtin "%sysfunc(getoption(work))/&txtfilename" ; */

/*By putting the data into the work dir, it will occupy addtional space*/
/*If knowing the data format, it is better to create dataset at the stage directly*/
/* data _null_; */
/*    using member syntax here */
/*    infile inzip(&txtdir/&txtfilename)  */
/*        lrecl=500 recfm=F length=length eof=eof unbuf; */
/*    file txtin lrecl=500 recfm=N; */
/*    input; */
/*    put _infile_ $varying32767. length; */
/*    return; */
/*  eof: */
/*    stop; */
/* run; */

data &sasdsdout (keep=chr pos rsid p SE BETA AF het_p ref alt);
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile inzip(&txtdir/&txtfilename) delimiter='09'x missover dsd firstobs=2;
&infile_command;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
if rsid="NA" then rsid=SNPID;
run;

%end;
%end;

%if &deleteZIP eq 1 %then %do;
/*Delete the gwas zip file to release space*/
%del_file_with_fullpath(fullpath=&zip);
%put the gwas gz file &gwas_gz_file is deleted to release space in SAS oOnDemaond;

/* %if &fi=1 %then %do;  */
/* proc import datafile=txtin dbms=tab out=&sasdsdout replace; */
/* %end; */
/* %else %do; */
/* proc import datafile=txtin dbms=tab out=&sasdsdout.&fi replace; */
/* %end; */

/* &extra_proc_import_codes; */
/* run; */

%end;

/*Delete the gwas file to release space*/
%del_file_with_fullpath(fullpath=%sysfunc(getoption(work))/&txtfilename);

*No need to change chr labels for HGI release 7;
*If using the following code, the output will be empty!;
/*Change char chr into numeric chr*/
/* %chr_format_exchanger( */
/* dsdin=&sasdsdout, */
/* char2num=1, */
/* chr_var=chr, */
/* dsdout=&sasdsdout); */

options compress=no;
%mend;

