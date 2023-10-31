*Note: this macro is only able to import HGI GWAS from GRASP but not HGI database;
%macro ImportHGICovidGWASFromZIP(zip,filename_rgx,sasdsdout,deleteZIP);
%local nfiles txtfilenames txtfilename;

%let infile_command=%str(
informat	chr	$5.;
informat	pos	best32.;
informat	REF	$1.;
informat	ALT	$2.;
informat	SNPID	$30.;
informat	all_meta_N	best12.;
informat	beta	best12.;
informat	se	best12.;
informat	p	best12.;
/* informat	meta_cases	best12.; */
/* informat	meta_controls	best12.; */
/* informat	meta_effective	best12.; */
informat	het_p	best12.;
informat all_meta_sample_N best12.;
informat	AF	best12.;
informat	rsid	$16.;
/* informat	hg38_chr	$5.; */
/* informat	hg38_pos	best32.; */
/* informat	REF1	$1.; */
/* informat	ALT2	$1.; */

format	chr	$5.;
format	pos	best32.;
format	REF	$1.;
format	ALT	$2.;
format	SNPID	$30.;
format	all_meta_N	best12.;
format	beta	best12.;
format	se	best12.;
format	p	best12.;
/* format	meta_cases	best12.; */
/* format	meta_controls	best12.; */
/* format	meta_effective	best12.; */
format	het_p	best12.;
format all_meta_sample_N best12.;
format	AF	best12.;
format	rsid	$16.;
/* format	hg38_chr	$5.; */
/* format	hg38_pos	best32.; */
/* format	REF1	$1.; */
/* format	ALT2	$1.; */


/* input CHR $ POS REF $ ALT $ SNPID $ all_meta_N beta se p meta_case meta_controls meta_effective  */
/*       het_p AF rsid $ hg38_chr $ hg38_pos REF $ ALT2 $; */
input CHR $ POS REF $ ALT $ SNPID $ all_meta_N beta se p 
      het_p all_meta_sample_N AF rsid $;
);


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

%if %sysevalf(&gzip_tag ne or &filename_rgx=txt) %then %do;
%let fname=%sysfunc(prxchange(s/(.*\/|\.zip|\.gz|\.tgz)//i,-1,&zip));
/* filename target "%sysfunc(getoption(work))/&fname"; */
/*gzip parameter is only available in latest SAS9.4M5*/

%if %sysevalf("&filename_rgx"="gz" or "&filename_rgx"="tgz") %then %do;
filename fromzip ZIP "&zip"  GZIP;
%end;
%else %do;
*for txt file;
filename fromzip "&zip";
%end;

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

/*Change char chr into numeric chr*/
%chr_format_exchanger(
dsdin=&sasdsdout,
char2num=1,
chr_var=chr,
dsdout=&sasdsdout);

options compress=no;
%mend;

