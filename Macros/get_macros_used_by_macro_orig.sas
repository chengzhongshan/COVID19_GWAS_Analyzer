%macro get_macros_used_by_macro_orig(/*This macro may run endlessly when the macro include its macro name without the Demo tag*/
macrorgx=.,
dir=%sysfunc(pathname(HOME))/Macros 
~/shared/Macros
/home/zcheng/SAS-Useful-Codes/Macros 
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros
/home/zhongshan/SAS-Useful-Codes/Macros
,
outdsd=macros,
verbose=0,
IsSASOnDemand=0
);


%let tgt_macro_rgx=&macrorgx;
*Keep the original target rgx for specific macros;
*Use the greedy rgx . to match all macros to obtain all submacros;
*Then use the original rgx to filter the results;
%let macrorgx=.;

%if &sysscp=WIN %then %do;
 %put Find your system is WIN, so we will make the value for your input var IsSASOnDemand=1;
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

*First round search submacros;
*Use number to record the searching times;
data _macros&i;
retain macro_i 0;
length file $1000. Macro_Info $1000.;
infile "&&path&i" lrecl=10000 obs=max;
input;
Macro_Info=_infile_;

*It is important to stop the processing when encounter these Demo codes;
if prxmatch("/Demo/i",Macro_Info) then stop;

file="&&path&i";
*Use regex to parse lines in macro for submacros used by the macro;
if prxmatch("/^(\s)?\%([^\s\(])+\(/i",Macro_Info) then do;
 call symputx('_macrodir_',trim(left(prxchange("s/(^.*[\/\\])[^\/\\]+.sas/$1/i",-1,file))));
 file=scan(file,-2,'/.');

 *Macro_Info=trim(left(prxchange("s/(^.*[\/\\])[^\/\\]+.sas/$1/i",-1,file))) || trim(left(prxchange("s/(?:\s?)\%([^\s\(]+)\(.*/$1/",-1,Macro_Info))) || ".sas";
 Macro_Info=trim(left(prxchange("s/(?:\s?)\%([^\s\(]+)\(.*/$1/",-1,Macro_Info)));
 macro_i=macro_i+1;
 if Macro_Info^=file then do;
   call symputx('totmacros',put(macro_i,3.));
   call symputx('submacro'||trim(left(put(macro_i,3.))),Macro_Info);
   stage=1;
   output;
 end;
end;
run;


%put **********************************************;
%put ;

%end;

data &outdsd;
set _macros:;
run;

*Print macro with specific style;
/*
proc print data=macros noobs;
*This only works when running SAS in non-terminal mode;
*var _all_ /style =[width=15in] 
*         style(data)=[font_face=arial font_weight=bold foreground=darkblue background=cxedf2f9 font_size=10pt];
*background=linen;
label Macro_Info="SAS Macro information";
run;
*/

proc datasets nolist;
delete _macros: macros_:;
run;

*Delete the sas internal str macro from the &outdsd;
data &outdsd;
set &outdsd;
if Macro_info="str" then delete;

*Now filter the results for target macros match with regular expression;
%longdsd2struct_dsd(
indsd=&outdsd,
key1st_var=file,
key2nd_var=Macro_Info,
structdsdout=&outdsd._struct,
max_iteration=100 
);

data &outdsd;
set &outdsd._struct(keep=file Macro_Info d:);
if prxmatch("/&tgt_macro_rgx/i",file);
proc sort data=&outdsd;by _all_;run;

/*proc print data=&outdsd;run;*/

%mend;

/*
*Demo code;
options mprint mlogic symbolgen;
x cd F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes;
%get_macros_used_by_macro(
macrorgx=.,
dir=/home/cheng.zhong.shan/Macros F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros /zcheng/Macros ~/shared/Macros /home/zcheng/SAS-Useful-Codes/Macros /LocalDisks/F/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros,
verbose=0,
outdsd=macros,
IsSASOnDemand=0
);

*/

