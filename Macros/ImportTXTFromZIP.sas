%macro ImportTXTFromZIP(zip,filename_rgx,sasdsdout,extra_proc_import_codes,deleteZIP);
%local nfiles txtfilenames txtfilename;

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
filename target "%sysfunc(getoption(work))/&fname";
/*gzip parameter is only available in latest SAS9.4M5*/
filename fromzip ZIP "&zip" GZIP;
data _null_;   
   infile fromzip;
   file target;
   input;
   put _infile_ ;
run;

/*just get top 10000 records for debugging*/
/* options obs=10000; */
proc import datafile=target dbms=tab out=&sasdsdout replace;
&extra_proc_import_codes;
run;
/*reset the max number of importing*/
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
filename txtin "%sysfunc(getoption(work))/&txtfilename" ;

/*By putting the data into the work dir, it will occupy addtional space*/
/*If knowing the data format, it is better to create dataset at the stage directly*/
data _null_;
   /* using member syntax here */
   infile inzip(&txtdir/&txtfilename) 
       lrecl=500 recfm=F length=length eof=eof unbuf;
   file txtin lrecl=500 recfm=N;
   input;
   put _infile_ $varying32767. length;
   return;
 eof:
   stop;
run;

%if &fi=1 %then %do; 
proc import datafile=txtin dbms=tab out=&sasdsdout replace;
%end;
%else %do;
proc import datafile=txtin dbms=tab out=&sasdsdout.&fi replace;
%end;

&extra_proc_import_codes;
run;

%end;
%end;

/*Do not put the deletion codes into the do loop, it will be failed to*/
/*importal other files if the zip contains multiple files*/
%if &deleteZIP eq 1 %then %do;
/*Delete the gwas zip file to release space*/
%del_file_with_fullpath(fullpath=&zip);
%put the gwas gz file &gwas_gz_file is deleted to release space in SAS OnDemaond;
%end;

/*Delete the gwas file to release space*/
%del_file_with_fullpath(fullpath=%sysfunc(getoption(work))/&txtfilename);

%mend;

/* options mprint mlogic symbolgen; */

/*Demo:This macro can import any text format file from a zip;
%importallmacros;
x cd ~/SAS-Useful-Codes/Macros;
%ImportTXTFromZIP(zip=SAS-macros-master.zip,filename_rgx=COPYING,sasdsdout=out,
extra_proc_import_codes=%str(getnames=no),deleteZIP=1);

*/
