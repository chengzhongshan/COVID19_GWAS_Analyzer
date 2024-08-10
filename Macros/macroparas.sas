%macro macroparas(
macrorgx=.,
dir=%sysfunc(pathname(HOME))/Macros 
H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros
~/shared/Macros
/home/zcheng/SAS-Useful-Codes/Macros 
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros
/home/zhongshan/SAS-Useful-Codes/Macros
,
verbose=0,
IsSASOnDemand=0,
numlines2print=10000,
output_macropara_dsd=Macro_paras,
print_outdsd=0
);

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
/*filename M&di pipe "RecursiveSearchDir.pl &_dir_ &macrorgx|grep 'no dir' -iv";*/
/*%put your dir for sas macro is &dir;*/
/*data macroparas_&di;*/
/*infile M&di;*/
/*length path $1000.;*/
/*input;*/
/*path=_infile_;*/
/*run;*/
 %list_files4dsd(
 dir=&_dir_,
 file_rgx=sas\s*$,
 dsdout=macroparas_&di
 );

*Use this tag to determine whether there are any macro matched with regulatory expression later;
%let file_tag=&di;

 data macroparas_&di;
 set macroparas_&di(rename=(fullpath=filename));
	*match with \ or /;
 where scan(filename,-2,'\/')='Macros';
 run;
 %end;
%end;

%else %do;
*Note: sas ondemand system would be LIN X64;
%if %FileOrDirExist(&_dir_) %then %do;
  *SAS OnDemand UE can not use pipe;
  *It is necessary to include list_files.sas for successfully running of listfiles2dsdInUE.sas;
  *%include "&macrodir/list_files.sas";
  %include "&_dir_/listfiles2dsdInUE.sas";
  *The follow macro will create table tmp_&di that contains the var filename;
  %listfiles2dsdInUE(&_dir_,sas\s*$,macroparas_&di);
  data macroparas_&di;
  set macroparas_&di;
			*match with \ or /;
  where scan(filename,-2,'\/')='Macros';
  run;
  *Use this tag to determine whether there are any macro matched with regulatory expression later;
  %let file_tag=&di;  
  %end;
 
 %end;

%end;

%if %sysfunc(exist(macroparas_&file_tag)) %then %do;
data macroparas;
set macroparas_:;
rename filename=path;
where prxmatch("/&macrorgx/i",filename);
run;
%end;
%else %do;
 %put no macros found match with the regular expression &macrorgx in the following dir:;
	%put &dir;
	%abort 255;
%end;

proc datasets lib=work noprint;
delete macroparas_:;
run;
%if &verbose=0 %then %do;
options notes;
%end;

proc sql noprint;
select count(*) into: n
from macroparas;
select compress(put(count(*),3.)) into: char_n
from macroparas;
select path into: path1 - : path&char_n
from macroparas;


%do i=1 %to &n;
%put ;
%put **********************************************;
%put Get the fullpath for your macro &i:;
%put &&path&i;
%put ;

/*%if %eval(&IsSASOnDemand=0 and %sysfunc(prxmatch(/LIN/,&sysscp))) %then %do;*/
/**x cat &&path&i|head -n 20;*/
/*x getsasmacrodemo &&path&i;*/
/*%end;*/
/*%else %do;*/

data _macros_;
length Macro_Info $500.;
infile "&&path&i" lrecl=10000 obs=&numlines2print;
input;
Macro_Info=_infile_;
run;
*Print macro with specific style;
title "Contents of first &numlines2print lines of SAS macro: &&path&i";
proc print data=_macros_ noobs;
var Macro_Info/style =[width=15in] 
         style(data)=[font_face=arial font_weight=bold foreground=darkblue background=cxedf2f9 font_size=10pt];
*background=linen;
label Macro_Info="SAS Macro information";
run;
run;

*Output macro parameters as a sas data set;
%let _macro_=%sysfunc(prxchange(s/.*\/([^\/]+).sas/$1/i,-1,&&path&i));
%put Target macro is %trim(&_macro_);

data _mparas&i(drop=tag Macro_info);
*Note: it is necessary to assign long length for macro_paras;
*Otherwise, the data step will not get the macro parameters;
*and the macro will not be included in the final output table;
length macro_paras $10000. macro $500.;
retain tag 0 macro_paras '';
set _macros_;
macro="&_macro_";
if prxmatch("/.macro\s+&_macro_/i",macro_info) then do;
  tag=1;
  macro_paras=prxchange("s/.*(&_macro_.*)/$1/i",-1,macro_info);
  if prxmatch("/&_macro_[\(][^\)]+[\)][;\s]*$/i",macro_paras) then do;
     tag=0;output;
  end;
end;
else if (tag=1) then do;
   macro_paras=catx(
   '',
   macro_paras,
   macro_info
  );
  
  if prxmatch("/[\)][;\s]*$/i",macro_paras) then do;
     tag=0;output;
  end;   
end;
/* %abort 255; */

*Now make both Linux and Windows use the same pure SAS codes to get SAS parameters;
/*%end;*/

%put **********************************************;
%put ;
%end;

*Combine all macro parameters into a single dataset;
data &output_macropara_dsd;
set _mparas:;
run;


proc datasets lib=work nolist;
delete _mparas: _macros_ Macroparas;
run;
title "Matched macro and its parameters";
%if &print_outdsd=1 %then %do;
proc print data=&output_macropara_dsd;
%print_nicer;
run;
%end;
title;

%mend;

/*
options mprint mlogic symbolgen;
x cd F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes;
%debug_macro;

%macroparas(
macrorgx=.,
dir=/home/cheng.zhong.shan/Macros 
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros /zcheng/Macros 
~/shared/Macros /home/zcheng/SAS-Useful-Codes/Macros /LocalDisks/F/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros
H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
verbose=0,
IsSASOnDemand=0,
numlines2print=50,
output_macropara_dsd=Macro_paras,
print_outdsd=1
);

*/

