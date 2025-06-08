%macro sas_pgm_printer(
pgmrgx=.,
dir=%sysfunc(pathname(HOME))/Macros
\stjude.sjcrh.local\data\ResearchHome\ClusterHome\zcheng\SAS-Useful-Codes\Macros
H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros
~/shared/Macros
/home/zcheng/SAS-Useful-Codes/Macros
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros
/home/zhongshan/SAS-Useful-Codes/Macros
,
verbose=0,
IsSASOnDemand=0,
numlines2print=10000,/*Assign value 0 to suppress the printing of pgm contents*/
output__sas_pgmpara_dsd=_sas_pgm_paras,
print_outdsd=0
);

%let not_print_pgm=0;
%if &numlines2print=0 %then %do;
 %let not_print_pgm=1;
 *Temporarily assign value 10 to the var just for running the macro to collect all sas pgms;
 %let numlines2print=10;
%end;
%if &sysscp=WIN %then %do;
%put Find your system is WIN, so we will change the value of your input var IsSASOnDemand as 0 if it is asigned as 1 at the beginning;
%let IsSASOnDemand=0;
%end;
 
%let ndirs=%sysfunc(countc(&dir,' '))+1;
%if &verbose=0 %then %do;
options nonotes;
%end;
 
%do di=1 %to &ndirs;
%let _dir_=%scan(&dir,&di,' ');
 
%if %sysfunc(prxmatch(/WIN|LIN|UNIX|LNX/,&sysscp)) and &IsSASOnDemand=0 %then %do;
%if %FileOrDirExist(&_dir_) %then %do;
/*filename M&di pipe "RecursiveSearchDir.pl &_dir_ &pgmrgx|grep 'no dir' -iv";*/
/*%put your dir for sas _sas_pgm is &dir;*/
/*data sas_pgm_printer_&di;*/
/*infile M&di;*/
/*length path $1000.;*/
/*input;*/
/*path=_infile_;*/
/*run;*/
%list_files4dsd(
dir=&_dir_,
file_rgx=sas\s*$,
dsdout=sas_pgm_printer_&di
);
 
*Use this tag to determine whether there are any _sas_pgm matched with regulatory expression later;
%let file_tag=&di;
 
data sas_pgm_printer_&di;
set sas_pgm_printer_&di(rename=(fullpath=filename));
*match with \ or /;
/*where scan(filename,-2,'\/')='_sas_pgms';*/
run;
%end;
%end;
 
%else %do;
*Note: sas ondemand system would be LIN X64;
%if %FileOrDirExist(&_dir_) %then %do;
*SAS OnDemand UE can not use pipe;
*It is necessary to include list_files.sas for successfully running of listfiles2dsdInUE.sas;
*%include "&_sas_pgmdir/list_files.sas";
%include "%sysfunc(pathname(HOME))/Macros/listfiles2dsdInUE.sas";
*The follow _sas_pgm will create table tmp_&di that contains the var filename;
%listfiles2dsdInUE(&_dir_,sas\s*$,sas_pgm_printer_&di);
data sas_pgm_printer_&di;
set sas_pgm_printer_&di;
*match with \ or /;
/*where scan(filename,-2,'\/')='_sas_pgms';*/
run;
/* %abort 255; */
*Use this tag to determine whether there are any _sas_pgm matched with regulatory expression later;
%let file_tag=&di;
%end;
 
%end;
 
%end;
 
 
%if %sysfunc(exist(sas_pgm_printer_&file_tag)) %then %do;
data sas_pgm_printer;
set sas_pgm_printer_:;
rename filename=path;
where prxmatch("/&pgmrgx/i",filename);
run;
%end;
%else %do;
%put no _sas_pgms found match with the regular expression &pgmrgx in the following dir:;
%put &dir;
%abort 255;
%end;
 
proc datasets lib=work noprint;
delete sas_pgm_printer_:;
run;
%if &verbose=0 %then %do;
options notes;
%end;
 
proc sql noprint;
select count(*) into: n
from sas_pgm_printer;
select compress(put(count(*),8.)) into: char_n
from sas_pgm_printer;
select path into: path1 - : path&char_n
from sas_pgm_printer;
 
 
%do i=1 %to &n;
%put ;
%put **********************************************;
%put Get the fullpath for your _sas_pgm &i:;
%put &&path&i;
%put ;
 
/*%if %eval(&IsSASOnDemand=0 and %sysfunc(prxmatch(/LIN/,&sysscp))) %then %do;*/
/**x cat &&path&i|head -n 20;*/
/*x getsas_sas_pgmdemo &&path&i;*/
/*%end;*/
/*%else %do;*/
 
data __sas_pgms_;
length sas_pgm_info $5000.;
infile "&&path&i" lrecl=10000 obs=&numlines2print;
input;
sas_pgm_info=_infile_;
run;
%if &not_print_pgm=0 %then %do;
*Print _sas_pgm with specific style;
title justify=left "Contents of first &numlines2print lines of sas pgm: &&path&i"
justify=left;
proc print data=__sas_pgms_ noobs;
var sas_pgm_info/style =[width=15in]
style(data)=[font_face=arial font_weight=bold foreground=darkblue background=cxedf2f9 font_size=10pt];
*background=linen;
label sas_pgm_info="SAS sas_pgm information";
run;
%end;
 
*Output _sas_pgm parameters as a sas data set;
%let _saspgm_=%sysfunc(prxchange(s/.*\/([^\/]+).sas/$1/i,-1,&&path&i));
%put Target _sas_pgm is %trim(&_saspgm_);
 
data _mparas&i;
length _sas_pgm $500.;
set __sas_pgms_;
pgm="&&path&i";
run;
 
*Now make both Linux and Windows use the same pure SAS codes to get SAS parameters;
/*%end;*/
 
%put **********************************************;
%put ;
%end;
 
*Combine all _sas_pgm parameters into a single dataset;
data &output__sas_pgmpara_dsd(keep=pgm);
set _mparas:;
run;
proc sort nodupkeys;by pgm;run;

 
 
proc datasets lib=work nolist;
delete _mparas: __sas_pgms_ _sas_pgmparas;
run;
title justify=left "Matched _sas_pgm" ;
%if &print_outdsd=1 %then %do;
proc print data=&output__sas_pgmpara_dsd noobs;
%print_nicer;
run;
%end;
title;
 
%mend;
 
/*
options mprint mlogic symbolgen;
x cd F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes;
%debug__sas_pgm;
 
%sas_pgm_printer(
pgmrgx=.,
dir=/home/cheng.zhong.shan/_sas_pgms
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/_sas_pgms /zcheng/_sas_pgms
~/shared/_sas_pgms /home/zcheng/SAS-Useful-Codes/_sas_pgms /LocalDisks/F/360yunpan/SASCodesLibrary/SAS-Useful-Codes/_sas_pgms
H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\_sas_pgms,
verbose=0,
IsSASOnDemand=0,
numlines2print=50,
output__sas_pgmpara_dsd=_sas_pgm_paras,
print_outdsd=1
);
 
*/
