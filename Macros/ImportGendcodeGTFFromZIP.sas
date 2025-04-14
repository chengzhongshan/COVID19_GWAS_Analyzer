%macro ImportGendcodeGTFFromZIP(
zip,
filename_rgx,
sasdsdout,
deleteZIP,
Use_zcat=0 /*if the gzip option is not availabe for old sas, use zcat in linux to replace it!*/
);
%local nfiles txtfilenames txtfilename;
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

%if &Use_zcat=1 %then %do;
filename fromzip pipe "zcat &zip";
%end;
%else %do;
filename fromzip ZIP "&zip" GZIP;
%end;

data &sasdsdout (drop=X:); 
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile fromzip delimiter='09'x missover dsd firstobs=6;
informat chr $5.;
informat X1 $5.;
informat type $15.;
informat st best32.;
informat end best32.;
informat X2 $1.;
informat strand $1.;
informat X3 $5. ;
informat info $1000. ;

format chr $5.;
format X1 $5.;
format type $15.;
format st best32.;
format end best32.;
format X2 $1.;
format strand $1.;
format X3 $5. ;
format info $1000. ;
input chr $ X1 $ type $ st end X2 strand $ X3 info $;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
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

data &sasdsdout (drop=X:);
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile inzip(&txtdir/&txtfilename) delimiter='09'x missover dsd firstobs=6;
informat chr $5.;
informat X1 $5.;
informat type $15.;
informat st best32.;
informat end best32.;
informat X2 $1.;
informat strand $1.;
informat X3 $5. ;
informat info $1000. ;

format chr $5.;
format X1 $5.;
format type $15.;
format st best32.;
format end best32.;
format X2 $1.;
format strand $1.;
format X3 $5. ;
format info $1000. ;
input chr $ X1 $ type $ st end X2 strand $ X3 info $;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
run;

%end;
%end;

%if &deleteZIP eq 1 %then %do;
/*Delete the gtf zip file to release space*/
%del_file_with_fullpath(fullpath=&zip);
%put the gtf gz file &zip is deleted to release space in SAS oOnDemaond;

/* %if &fi=1 %then %do;  */
/* proc import datafile=txtin dbms=tab out=&sasdsdout replace; */
/* %end; */
/* %else %do; */
/* proc import datafile=txtin dbms=tab out=&sasdsdout.&fi replace; */
/* %end; */

/* &extra_proc_import_codes; */
/* run; */

%end;

/*Delete the gtf file to release space*/
%del_file_with_fullpath(fullpath=%sysfunc(getoption(work))/&txtfilename);

/*Change char chr into numeric chr*/
%chr_format_exchanger(
dsdin=&sasdsdout,
char2num=1,
chr_var=chr,
dsdout=&sasdsdout);

*drop the column info to save space;
data &sasdsdout(drop=info);
*enable genesymbol and ensembl id the same length;
*as some gene without genesymbols will be asigned with ensembl ids;
length genesymbol $30. ensembl $30. ensembl_transcript $100.;
set &sasdsdout;
ensembl=prxchange('s/gene_id\s+\"([^\"]+)\".*/$1/',-1,info);
*Also capture transcript ids of each gene;
ensembl_transcript=prxchange('s/.*transcript_id\s+\"([^\"]+)\".*/$1/',-1,info);
genesymbol=prxchange('s/.*gene_name\s+\"([^\"]+)\".*/$1/',-1,info);
ensembl_transcript=trim(left(genesymbol))||":"||trim(left(ensembl_transcript));
if prxmatch('/protein_coding/i',info) then protein_coding=1;
else protein_coding=0;
run;
options compress=no;
%mend;

