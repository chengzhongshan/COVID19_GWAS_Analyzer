%macro get_macros_used_by_macro(/*This macro may run endlessly when the macro include its macro name without the Demo tag*/
macrorgx=.,/*No need to include \.sas, as the macro will only keep sas script having prefix matching with the macrorgx!*/
dir=%sysfunc(pathname(HOME))/Macros 
~/shared/Macros
/home/zcheng/SAS-Useful-Codes/Macros 
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros
/home/zhongshan/SAS-Useful-Codes/Macros
,
outdsd=macros,
verbose=0,
IsSASOnDemand=0,
OnlySearchSubMacroIn1stLevel=1 /*Restrict the macro to only search 1st-level submacros used by matched macro, which would be very quick!
Provide value 0 to search all macros to identify all-level sumacros used by a macro and its submacros!*/
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
*No need to filter, as the updated macrorgx is . for matching anything.;
/*where prxmatch("/&macrorgx/i",filename);*/
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

*For debugging, only keep macros matching with macrorgx;
*If filtering macro with regular expression here, the macro is unable to search other macros that use submacros;
*This means that the macro will be only able to detect 1st-level submacros used by the matched macro;
%if &OnlySearchSubmacroIn1stLevel=1 %then %do;
data macroparas;
set macroparas;
where prxmatch("/&tgt_macro_rgx/i",path);
run;
%end;

proc sql noprint;
select count(*) into: n
from macroparas;
select compress(put(count(*),3.)) into: char_n
from macroparas;
select path into: path1 - : path&char_n
from macroparas;


%do i=1 %to &n;
/*%do i=1 %to 30;*for debugging;*/
%put ;
%put **********************************************;
%put Get the fullpath for your macro &i:;
%put &&path&i;
%put ;

*First search submacros;
*Use number to record the searching times;
data _macro_info_;
infile "&&path&i" lrecl=10000 obs=max;
input;
Macro_Info=_infile_;
run;

*Output macro parameters as a sas data set;
%let _macro_=%sysfunc(prxchange(s/.*[\/\\]([^\/\\]+).sas/$1/i,-1,&&path&i));
%put Parsing macro parameters for the macro &_macro_;
data _parameters4macro&i (drop=tag Macro_info);
length macro_paras $32767. macro $1000.;
retain tag 0 macro_paras '';
set _macro_info_;
macro="&_macro_";
if prxmatch("/.macro\s+&_macro_([\s\(;]+|(\/parmbuff;)?)/i",macro_info) then do;
/*if prxmatch("/.macro\s+&_macro_/i",macro_info) then do;*/
  tag=1;

  *for debugging, put output at the end of one of the following prxchange command to evaluate the output;

  *Note: it is necessary to add two dots after &_macro_, as sas resolve &_macro_. as &_macro_;
  macro_paras=prxchange("s/.*(&_macro_..*)/$1/i",-1,macro_info);

  *For macros using parmbuff;
  macro_paras=prxchange("s/\/parmbuff;/;/i",-1,macro_paras);
  *Further remove pct macro;
  macro_paras=prxchange("s/.macro//i",-1,macro_paras);

  if prxmatch("/&_macro_\s*[;]/",macro_paras) then macro_paras="&_macro_;";

  if prxmatch("/&_macro_[\s\(]+[^\)\(]+[\)]\s*[;]\s*$/",macro_paras) or macro_paras="&_macro_;" 
  then do;
     tag=0;output;
  end;
end;
else if (tag=1) then do;
   macro_paras=catx(
   '',
   macro_paras,
   macro_info
  );
  if prxmatch("/[\)]\s*[;]\s*$/",macro_paras) then do;
     tag=0;output;
  end;   
end;
run;

*Output macros and its corresponding submacros;
data _macros&i;
/*retain macro_i 0;*/
length file $1000. Macro_Info $32767.;
set _macro_info_;

/*infile "&&path&i" lrecl=10000 obs=max;*/
/*input;*/
/*Macro_Info=_infile_;*/

*It is important to stop the processing when encounter these Demo codes;
if prxmatch("/Demo/i",Macro_Info) then stop;

file="&&path&i";
 call symputx('_macrodir_',trim(left(prxchange("s/(^.*[\/\\])[^\/\\]+.sas/$1/i",-1,file))));
 file=scan(file,-2,'/.\');
*Use regex to parse lines in macro for submacros used by the macro;
if prxmatch("/^(\s)?\%([^\(])+\(/i",Macro_Info) then do;

 *Macro_Info=trim(left(prxchange("s/(^.*[\/\\])[^\/\\]+.sas/$1/i",-1,file))) || trim(left(prxchange("s/(?:\s?)\%([^\s\(]+)\(.*/$1/",-1,Macro_Info))) || ".sas";
 Macro_Info=trim(left(prxchange("s/^.*(?:\s?)\%([^\s\(\%]+)\(.*/$1/",-1,Macro_Info)));
 Macro_Info=prxchange('s/\%macro\s+([^\(]+).*$/$1/i',-1,Macro_Info);
*Further remove the parmbuff if only;
 Macro_info=prxchange('s/\/parmbuff;//i',-1,Macro_info); output;
/* macro_i=macro_i+1;*/
 if Macro_Info^=file then do;
/*   call symputx('totmacros',put(macro_i,3.));*/
/*   call symputx('submacro'||trim(left(put(macro_i,3.))),Macro_Info);*/
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
*remove duplicate records;
proc sort data=&outdsd;
by _all_;
run;

data parameters;
set _parameters4macro:;
run;
/*%abort 255;*/

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
delete _macros: macros_: _parameters4macro:  _macro_info_;
run;

*Delete the sas internal str macro from the &outdsd;
/*data &outdsd;*/
/*set &outdsd;*/
/**exclude these sas system macros;*/
/*if Macro_info in ("str", "length", "sysget", "unquote")  then delete;*/
/*run;*/
data _users_macros_(keep=macro);
set Macroparas;
macro=prxchange("s/.*[\/\\]([^\/\\]+).sas/$1/i",-1,path);
run;
*Now exclude SAS system macros by intersecting with users macros;
proc sql;
create table &outdsd as
select a.*
from &outdsd as a,
        _users_macros_ as b
where a.Macro_Info=b.macro;


*Now filter the results for target macros match with regular expression;
%longdsd2struct_dsd(
indsd=&outdsd,
key1st_var=file,
key2nd_var=Macro_Info,
structdsdout=&outdsd.Structure,
max_iteration=100 
);

*Now add back these macros that do not use other macros;
data _all_macros_(keep=file);
set macroparas;
file=path;
file=prxchange('s/.*[\/]([^\/]+)\.sas/$1/i',-1,file);
run;

proc sort data=&outdsd.Structure;
by file;
proc sort data=_all_macros_;
by file;
data &outdsd.Structure;
merge &outdsd.Structure _all_macros_;
by file;
run;


data &outdsd;
set &outdsd.Structure(keep=file Macro_Info d:);
if prxmatch("/&tgt_macro_rgx/i",file);
run;

%VarnamesInDsd(indsd=&outdsd,Rgx=^d\d+,match_or_not_match=1,outdsd=submacro_varnames);
proc sql noprint;
select count(*) into: tot_submacros
from submacro_varnames;

data &outdsd ;
  set &outdsd;
  %Rename_OldPrefix2NewPrefix(d, submacro, &tot_submacros);
 rename file=Macro Macro_info=submacro0;
run;

proc sort data=&outdsd;by _all_;run;
/*proc print data=&outdsd;run;*/

*https://communities.sas.com/t5/ODS-and-Base-Reporting/Proc-Report-Merging-cells-when-grouped-and-vertical-center/td-p/302710;
*it is important to add spanrows and style(column) statements;
title "Main macro and its corresponding submacros in structure format in the dsd &outdsd";
proc report data=&outdsd spanrows;
column Macro submacro:;
*Need to use order but not group for define clause;
define Macro /order style(column)=[vjust=middle just=left];
define submacro0 /order style(column)=[vjust=middle just=left];
*This will fail when other submacro columns contain empty elements;
*As only macro with the specified level of tot_submarcros will be printed;
/*%do smi=0 %to &tot_submacros;*/
/*define submacro&smi /group style(column)=[vjust=middle just=left];*/
/*%end;*/
run;


data Macroparas(rename=(path=Macro));
set Macroparas;
path=prxchange("s/.*Macros\/([^\/]+)\.sas/$1/i",-1,path);
if prxmatch('/\//',path) then delete;
run;

*Now link all submacros for the main macro and print them;
*ensure the macros is sorted by the 1st column, i.e., varname Macro;
*The codes commented does not work well;
/*data &outdsd.Linked(keep=Macro submacrs);*/
/*length grp $100. submacrs $1000.;*/
/*retain grp '' submacrs '';*/
/*array X{*} $100. submacro0-submacro4;*/
/*set &outdsd;*/
/*if first.Macro then do;*/
/* grp=Macro;*/
/* submacrs=catx(', ', of submacro0-submacro4);*/
/*end;*/
/*else do;*/
/* submacrs=catx(', ',submacrs,catx(', ', of submacro0-submacro4));*/
/*end;*/
/**Remove duplicate elements;*/
/*submacrs=prxchange('s/([^,]+),(.*)\b\1/$1,$2/',-1,submacrs);*/
/*submacrs=prxchange('s/, , /, /',-1,submacrs);*/
/*if last.Macro then output;*/
/*by Macro;*/
/*run;*/

%Put Now running time-consuming mult_columns_linker_by_grp_var for the input dataset &outdsd.Linked;

%mult_columns_linker_by_grp_var(
indsd=&outdsd,
outdsd=&outdsd.Linked,
grp_var=Macro,
vars2link=submacro0-submacro10,
linker=,
output_var4linked_vars=_submacrs_ 
);


*lookup all macros with these macros having submacros;
proc sql;
create table &outdsd.Linked as
select a.Macro,b._submacrs_ as submacrs
from Macroparas as a
left join
&outdsd.Linked as b
on a.Macro=b.Macro;

create table &outdsd.Linked as
select b.Macro_paras,a.*
from &outdsd.Linked as a
left join
Parameters as b
on a.Macro=b.Macro;

*Make submacro as empty if it is the same as the main macro;
data &outdsd.Linked;
set &outdsd.Linked;
if Macro=submacrs then submacrs="";
if macro_paras="" then macro_paras="Probable confict between macro name and its sas filename";
run;

/**Now further get macro annotations and add them into the dataset macros;*/
proc import datafile="&_macrodir_/Available_SAS_Macros_and_its_annotations4STAR_PROTOCOL.csv" dbms=csv out=macro_anno replace;
getnames=yes;guessingrows=max;
run;

proc sql;
create table &outdsd.Linked as
select b.Macro_categories,a.Macro,b.Annotation,
a.macro_paras as Parameters,a.submacrs as Submacros
from &outdsd.Linked as a
left join
macro_anno as b 
on a.Macro=b.Macro;

title "Main macro and its corresponding submacros in linked format in the dsd &outdsd.Linked";
proc print data=&outdsd.Linked;
%print_nicer;
run;
proc datasets lib=work nolist;
delete Macros_: Submacro_varnames Macroparas;
run;

%mend;

/*
*Demo code;

*For SAS OnDemand for Academics;
%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

%get_anno4macro(
macro_rgx=.,
anno_rgx=
);

%get_macros_used_by_macro(
macrorgx=eQTL,
dir=%sysfunc(pathname(HOME))/Macros,
verbose=1,
outdsd=macros,
IsSASOnDemand=1,
OnlySearchSubMacroIn1stLevel=1 
);



*For local SAS 9.4 Workbench;

options mprint mlogic symbolgen;
x cd F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes;

*Change the macrorgx to . for searching all macros;

%get_macros_used_by_macro(
macrorgx=.,
dir=/home/cheng.zhong.shan/Macros 
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros 
/zcheng/Macros ~/shared/Macros /home/zcheng/SAS-Useful-Codes/Macros 
/LocalDisks/F/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros
H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros
,
verbose=1,
outdsd=macros,
IsSASOnDemand=0,
OnlySearchSubMacroIn1stLevel=0
);

*The following has been implemented into the above sas macro;
*Now further get macro parameters and add them into the dataset macros;
%macroparas(
macrorgx=.,
dir=/home/cheng.zhong.shan/Macros 
F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros /zcheng/Macros 
~/shared/Macros /home/zcheng/SAS-Useful-Codes/Macros /LocalDisks/F/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros
H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
verbose=0,
IsSASOnDemand=0,
numlines2print=100,
output_macropara_dsd=Macro_paras,
print_outdsd=0
);

proc sql;
create table macros_linked_ as
select a.*,b.macro_paras
from macros_linked as a
left join
macro_paras as b 
on a.Macro=b.Macro;


*/

