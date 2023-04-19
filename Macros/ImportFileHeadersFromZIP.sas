%macro ImportFileHeadersFromZIP(
zip=,/*Only provide file with .gz, .zip, or common text file without comporession*/
filename_rgx=.,
obs=max,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(firstobs=1 obs=10;input;info=_infile_;),
use_zcat=0   /*This macro will use 7z in Windows and gzip in newer SAS or SAS OnDemand;
              it also can use zcat in Linux*/
);

*obs=max allows the macro to read all lines from files within zip or gzip;
*If the purpose is to read headers, please use obs=10;
*Adjust the length for the input line;
*If supply infile_command, make sure the same number was asigned to obs for the macro var and infile_command;

%local nfiles txtfilenames txtfilename;
*Use a fake separator '_____' to read each single line into the var info;

*Use default infile command;
%if "&infile_command"="" %then %do;
  %let infile_command=%str(
  /* delimiter='09'x truncover dsd firstobs=1 obs=&obs; */
  firstobs=1 obs=&obs;
  input;
  info=_infile_;
  );
%end;

options compress=yes;
%local gzip_tag;
/*do not quote the keyword gz for index function*/
*This is not comprehensive, and file with gz.tmp will be matched;
*7zip will generate gz.tmp file;
/*%if %index(&zip,gz) %then %do;*/
%if %index(&zip,gz) and (not %index(&zip,gz.tmp)) %then %do;
	%let gzip_tag=gzip;
%end;
%else %if (%index(&zip,zip)) %then %do;
    %let gzip_tab=zip;
%end;
%else %do;
    *This would be for uncompressed file;
    %let gzip_tag=;
%end;

%if &filename_rgx eq %then %do;
   %let filename_rgx=txt;
%end;

%if &sasdsdout eq %then %do;
  %let sasdsdout=txtdsd;
%end;

%if "&gzip_tag"="gzip" %then %do;
*Working on gz file;

%let fname=%sysfunc(prxchange(s/(.*\/|\.zip|\.gz|\.tgz)//i,-1,&zip));
/* filename target "%sysfunc(getoption(work))/&fname"; */
/*gzip parameter is only available in latest SAS9.4M5*/
/* identify a temp folder in the WORK directory */
/* Note: SAS can not get the filenames included a gz file */
/* SAS is only able to read the gz data as a whole */

*Make this macro runnable for linux SAS version lower than 9.4;
%if &use_zcat=1 %then %do;
 %sysexec zcat &zip | head -n 2;
%end;

%if &sysrc=0 and &use_zcat=1 %then %do;
 filename fromzip pipe "zcat &zip";
%end;
%else %do;
 %if "&sysscp"="WIN" %then %do;
	*Need to use 7zip in Windows;
	*Uncompress gz file;
 *Actionable command: 7z e B1_vs_B2.zscore.txt.gz -y;
	%let _gzfile_=%scan(&zip,-1,/\);
	*need to consider [\/\\] for the separator of &zip;
	%let _gzdir_=%sysfunc(prxchange(s/(.*)[\/\\][^\/\\]+/$1/,-1,&zip));
	*Need to confirm whether the _gzdir_ is parsed correctly;
	*When the &zip var only contains relative path without '.' at the beginning of the dir string;
	*The prxchange function can not generate right dir;
	%if %direxist(&_gzdir_) %then %do;
	 %put your gz file dir is &_gzdir_, which exists;
	%end;
	%else %do;
		%put your gz file dir is &_gzdir_, but which does not exist;
		%abort 255;
	%end;


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
	filename fromzip "&_gzdir_/&filename4dir/*";
	%end;
	%else %do;
  filename fromzip ZIP "&zip" GZIP;
	%end;
%end;

data &sasdsdout; 
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile fromzip 
&infile_command;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
run;
filename fromzip clear;
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

%else %if ("&gzip_tag"="zip") %then %do;
*Working on zip file;

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

data &sasdsdout ;
length file $100.;
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile inzip(&txtdir/&txtfilename)
&infile_command;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
file="&txtfilename";
run;

%end;
%end;

%else %do;
*Working on uncompressed file directly!;

filename fromfile "&zip";
data &sasdsdout; 
%let _EFIERR_=0;/*set the error detection macro variable*/
/* infile target delimiter='09'x missover dsd firstobs=2; */
infile fromfile
&infile_command;
if _error_ then call symputx('_ERIERR_',1);/*set error detection macro variable*/;
run;
filename fromfile clear;

%end;

%if &deleteZIP eq 1 %then %do;
/*Delete the gwas zip file to release space*/
%del_file_with_fullpath(fullpath=&zip);
%put the input gz file &txtfilename is deleted to release space in SAS oOnDemaond;

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
/* %chr_format_exchanger( */
/* dsdin=&sasdsdout, */
/* char2num=1, */
/* chr_var=chr, */
/* dsdout=&sasdsdout); */

options compress=no;
%mend;

/*Demo:
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*Important:
*The macro can process the following files;
*Only provide file with .gz, .zip, or common text file without comporession;

*********************************Demo 1******************************;
%let zipfile=/home/cheng.zhong.shan/data/GTEx_Analysis_v8_sbgenes.tar.gz;
*%let zipfile=/home/cheng.zhong.shan/data/signif.sbgenes.txt.gz;

*Get file headers;
%ImportFileHeadersFromZIP(
zip=&zipfile,
filename_rgx=.,
obs=2,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(firstobs=2 obs=2;input;info=_infile_;)
);

*Get column var lengths;
filename inzip zip "&zipfile" gzip;
%get_numeric_table_vars_length(
filename_ref_handle=inzip,
total_num_vars=5,
macro_prefix4NumVarLen=NumVarLen,
firstobs=2,
first_input4charvars=grp tissue,
macro_prefix4CharVarLen=CharVarLen,
dlm='09'x
);
filename inzip clear;

*Adjust input var lengths and types;
%ImportFileHeadersFromZIP(
zip=&zipfile,
filename_rgx=gz,
obs=max,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(
firstobs=2 obs=max delimiter='09'x truncover;
length gene :$17. tissue :$37.;
input gene $ tissue effsize effsize_se lfsr;
)
);

**************************Demo 2***************************;
%let gzfile=/home/cheng.zhong.shan/data/signif.sbgenes.txt.gz;
%ImportFileHeadersFromZIP(
zip=&gzfile,
filename_rgx=gz,
obs=max,
sasdsdout=x,
deleteZIP=0
infile_command=%str(firstobs=1 obs=10;input;info=_infile_;)
);

*Get column var lengths;
%get_numeric_table_vars_length(
filename_ref_handle=inzip,
total_num_vars=5,
macro_prefix4NumVarLen=NumVarLen,
firstobs=2,
first_input4charvars=grp tissue,
macro_prefix4CharVarLen=CharVarLen,
dlm='09'x
);

*Adjust input var lengths and types;
%ImportFileHeadersFromZIP(
zip=&gzfile,
filename_rgx=gz,
obs=max,sasdsdout=x,
deleteZIP=0,
infile_command=%str(
firstobs=2 obs=max delimiter='09'x truncover;
length gene :$30. tissue :$50.;
input gene $ tissue effsize effsize_se lfsr;
)
);

*/


