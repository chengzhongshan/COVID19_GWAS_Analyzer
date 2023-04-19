%macro ImportCovidGWASFromZIP(zip,filename_rgx,sasdsdout,deleteZIP);
%local nfiles txtfilenames txtfilename;
options compress=no;
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

filename fromzip ZIP "&zip" GZIP;
data &sasdsdout (keep=chr pos rsid p SE BETA N allele1 allele2 imputationInfo); 
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile fromzip delimiter='09'x truncover dsd firstobs=2;
informat chr $5.;
informat Pos best32.;
informat rsid $16.;
informat SNPID $30.;
informat allele1 $1.;
informat allele2 $2.;
informat AF_allele2 best12.;
informat imputationInfo best32. ;
informat N best12. ;
informat SE best12. ;
informat p best12. ;

format CHR $5. ;
format POS best12. ;
format rsid $16. ;
/*This var is too long and is not useful*/
format SNPID $10. ;
format Allele1 $1. ;
format Allele2 $2. ;
format AF_Allele2 best12. ;
format imputationInfo best12. ;
format N best12. ;
format BETA best12. ;
format SE best12. ;
format p best12. ;
*CHR POS rsid SNPID Allele1 Allele2 AF_Allele2 imputationInfo N BETA SE p.value;
input CHR $ POS rsid $ SNPID $ Allele1 $ Allele2 $ AF_Allele2 imputationInfo N BETA SE p;
*filter records based on AF and imputation score!;
if AF_Allele2 > 0.01 and imputationInfo > 0.6;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
run;
/* %abort 255; */

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

data &sasdsdout (keep=chr pos rsid p SE BETA N allele1 allele2 imputationInfo);
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile inzip(&txtdir/&txtfilename) delimiter='09'x truncover dsd firstobs=2;
informat chr $5.;
informat Pos best32.;
informat rsid $16.;
informat SNPID $30.;
informat allele1 $1.;
informat allele2 $2.;
informat AF_allele2 best12.;
informat imputationInfo best32. ;
informat N best12. ;
informat SE best12. ;
informat p best12. ;

format CHR $5. ;
format POS best12. ;
format rsid $16.;
format SNPID $10. ;
format Allele1 $1. ;
format Allele2 $2. ;
format AF_Allele2 best12. ;
format imputationInfo best12. ;
format N best12. ;
format BETA best12. ;
format SE best12. ;
format p best12. ;
*CHR POS rsid SNPID Allele1 Allele2 AF_Allele2 imputationInfo N BETA SE p.value;
input CHR $ POS rsid $ SNPID $ Allele1 $ Allele2 $ AF_Allele2 imputationInfo N BETA SE p;
*filter records based on AF and imputation score!;
if AF_Allele2 > 0.01 and imputationInfo > 0.6;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
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

/*Change char chr into numeric chr*/
%chr_format_exchanger(
dsdin=&sasdsdout,
char2num=1,
chr_var=chr,
dsdout=&sasdsdout);

options compress=no;
%mend;

