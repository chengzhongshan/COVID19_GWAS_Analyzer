%macro deseq_normalization(
dsdin,/*Note: to save space, the input dsd will be replace*/
read_vars,
dsdout,
readcutoff=3,
cellcutoff=5
);
/*readcutoff and cellcutoff will be used to exclude genes NOT passing the filters:
at least the number of cells expressing at least the number of reads*/

*Alternative way to normalize long format sas data;
*in proc sql, geomean can calculated by group with:;
*exp(mean(log(var)));

/* %getnumorcharvars4dsd(indsd=&dsdin,outdsd=info4chars,numeric=0); */
/* proc sql noprint; */
/* select name into: char_vars separated by ',' */
/* from info4chars;  */
/* select name into: _char_vars_ separated by ' ' */
/* from info4chars;  */
/* %put These character vars are found in your input dataset: &char_vars; */
data rownames;
set &dsdin(keep=_character_);
n=_n_;
run;

*this will overwrite original dataset to save a lot of space;
data &dsdin (keep=n reads i);
*To save space, only keep numeric vars;
set &dsdin(keep=_numeric_);
array T{*} _numeric_;
*Filter genes by reads and cell number;
tag=0;
*include the numeric order for rownames;
*this will eliminated the memory intensive procdure of sorting;
n=_n_;
do i=1 to dim(T);
 if T{i}>=&readcutoff then tag=tag+1;
end;
do i=1 to dim(T);
   reads=T{i};
   *Only export read value >0;
   if reads>0 and tag>=&cellcutoff then output;
end;
run;

*filter rownames by excluding some of them not passed the read and cell threshold;
proc sql;
create table rownames(drop=n) as
select a.*
from rownames as a,
     (select unique(n) as n from &dsdin (keep=n)) as b
     where a.n=b.n
order by n;


*Implement the calculation of geomean and normalization into datasetp;
*as proc sql is very memory intensive;

*The original code is too memory intensive;
*leading to SAS OnDemand out of memory;
********************************************************;
/*proc sql;*/
/*create table &dsdin as*/
/*select *,reads/exp(mean(log(reads))) as _reads*/
/*from &dsdin*/
/*group by n;*/
/*/* group by &char_vars; */*/
/*/* SAS failed as out of memory! */*/
/*/* order by &char_vars, i; */*/
/**/
/**Note: need to drop _reads in the final &dsdin to save space;*/
/**Failed to drop _reads in creating the table &dsdin;*/
/*proc sql;*/
/*create table &dsdin as*/
/*select n,i,*/
/*/*        round(reads/median(_reads),0.1) as reads */*/
/*round(reads/median(_reads)) as reads format=12.0*/
/*from &dsdin*/
/*group by i;*/
/*/* SAS failed as out of memory! */*/
/*/* order by &char_vars, i; */*/
/*proc sort data=&dsdin;*/
/*by n i;*/
/*run;*/
********************************************************;

*Try to avoid sorting and use hash to calcuate geomean and median for normalization;
*Note: the output can be the same dsd;
%deseq_normalization4longdsd(
indsd=&dsdin,
outdsd=&dsdin,
key4row=n,
key4col=i,
val_var=reads
);

%put going to reduce dsd size by using length command;
%let size=%FileAttribs(%sysfunc(getoption(work))/&dsdin..sas7bdat);
%put unreduced dsd size is &size Mb;

/*data _null_; */
/*do i=1 to 10000; */
/*a=trunc(i,3); */
/*if a ^=i then do; call symput ('max_3' , a); */
/*output; stop; */
/*end; */
/*end; */
/*run; */
/**/
/*proc sql noprint;*/
/*select max(reads) into: max_reads*/
/*from &dsdin;*/
/*%let max_len=3;*/
/*%if %sysevalf( &max_reads > &max_3 or &max_reads < -&max_3) %then %do; */
/*%if %sysevalf(&max_reads ne %sysfunc(trunc( &max_reads, 7 ))) %then %let max_len=8; %else */
/*%if %sysevalf(&max_reads ne %sysfunc(trunc( &max_reads, 6 ))) %then %let max_len=7; %else */
/*%if %sysevalf(&max_reads ne %sysfunc(trunc( &max_reads, 5 ))) %then %let max_len=6; %else */
/*%if %sysevalf(&max_reads ne %sysfunc(trunc( &max_reads, 4 ))) %then %let max_len=5; %else */
/*%if %sysevalf(&max_reads ne %sysfunc(trunc( &max_reads, 3 ))) %then %let max_len=4;*/
/*%end; */
/**/
/*data &dsdin(drop=reads);*/
/*length _reads_ &max_len.;*/
/*set &dsdin;*/
/*_reads_=reads;*/
/*run;*/
/*data &dsdin;*/
/*set &dsdin;*/
/*rename _reads_=reads;*/
/*run;*/
/*%let size=%FileAttribs(%sysfunc(getoption(work))/&dsdin..sas7bdat);*/
/*%put after reduction, the dsd size is &size Mb;*/

%squeez_single_num_var_length(
dsdin=&dsdin,
var=reads);


*The compress option will not reduce dsd size;
*Only the above length command will do;
/*options compress=yes;*/
proc transpose data=&dsdin out=&dsdin(drop=_name_) prefix=V;
var reads;
id i;
by n;
/* by &_char_vars_; */
run;
/*options compress=no;*/

/* proc print data=&dsdin;run; */
*add rownames back to the table;
*make missing value as 0;
data &dsdin;
set &dsdin(drop=n);
array N{*} _numeric_;
do i=1 to dim(N);
  if N{i}=. then N{i}=0;
end;
drop i;

data &dsdin;
set &dsdin;
set rownames;
run;

*rename the &dsdin as &dsdout;
%if "&dsdin"^="&dsdout" %then %do;
%delete_sas_dsd(&dsdout);
%rename_sas_dsd(
dsdin=&dsdin,
dsdout=&dsdout
);
%end;
*If the dsdin and dsdout are the same, no need to change name!;


******Old codes for learning*******;
/* options compress=yes; */
/* *The length of the value of the macro variable READ_VARS (65540) can not exceed the maximum length (65534).; */
/* %if "&read_vars"="_numeric_" %then %do; */
/*  *Get all numeric vars if supplying _numeric_ to match all numeric vars; */
/*  %getnumorcharvars4dsd(indsd=&dsdin,outdsd=info,numeric=1); */
/*  proc sql noprint; */
/*  select count(*) into: nvars */
/*  from info; */
/*  *make the macro number left adjust; */
/*  %let nvars=%sysfunc(left(&nvars)); */
/*  *generate single macro var for each single var; */
/*  *This will avoid of the truncation of too many chars in a single macro var; */
/*  proc sql noprint; */
/*  select trim(left(name)) into: read_var1- :read_var&nvars */
/*  from info; */
/* %end; */
/* %else %do; */
/*  *Generate single macro var for each var; */
/*  %let nvars=%ntokens(&read_vars); */
/*  %do i=1 %to &nvars; */
/*    %let read_var&i=%scan(&read_vars,&i); */
/*  %end; */
/* %end; */
/*  */
/* %put Target columns are: from &read_var1 to &&read_var&nvars; */
/* *No need to print so many macro vars; */
/* %do i=1 %to &nvars; */
/*  %put &&read_var&i; */
/* %end; */
/*  */
/* *Also generate macro vars for char vars; */
/* *As there would be few char vars, we just use proc sql to generate macro vars; */
/* %getnumorcharvars4dsd(indsd=&dsdin,outdsd=info4chars,numeric=0); */
/* proc sql noprint; */
/* select name into: char_vars separated by ',' */
/* from info4chars;  */
/* %put These character vars are found in your input dataset: &char_vars; */
/*  */
/* *QC matrix; */
/* *reads >3 at least in 5 cells; */
/* data &dsdout(drop=i where=(tag>=&cellcutoff)); */
/* set &dsdin; */
/* array X{*}  */
/* %do vi=1 %to &nvars; */
/*   &&read_var&vi  */
/* %end; */
/* ; */
/* tag=0; */
/* do i=1 to dim(X); */
/*  if X{i}=0 then do; */
/*   X{i}=.; */
/*  end; */
/*  *count genes with reads >1 at least in 5 cells; */
/*  if X{i} > &readcutoff then tag=tag+1; */
/* end; */
/* gm=geomean(of  */
/* %do vi=1 %to &nvars; */
/*   &&read_var&vi */
/* %end; */
/* ); */
/* run; */
/*  */
/* *It is a pity that the sql procedure update can not include summary calculation for ; */
/* *the same var, such as var=var/median(var); */
/* *So it is necessary to use sql create table step; */
/* *Here, if there are >100000 columns, it will generate >2*100000 columns; */
/* *Old codes with bugs; */
/* proc sql; */
/* create table &dsdout (drop= */
/* %do vi=1 %to &nvars; */
/*   &&read_var&vi */
/* %end; */
/* ) as */
/* select *, */
/*  %do i=1 %to &nvars; */
/*    %let var=&&read_var&i; */
/* 	  %if %eval(&i<&nvars) %then %do; */
/* 		     &var/median(&var/gm) as _&var, */
/* 			%end; */
/* 			%else %do; */
/* 		     &var/median(&var/gm) as _&var */
/* 			%end; */
/*  %end; */
/* from &dsdout; */
/* quit; */
/* *New codes with bugs fixed; */
/* *Just select all charcter columns, and other newly created columns of _&var; */
/* *All character vars are included in the macro var &char_vars; */
/* *Use space in the shared folder; */
/* *Note: the round function will reduce data size; */
/* libname sh "/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan"; */
/* *To save space, just overwrite the var and its dataset; */
/* *Previous codes just create a new var _&var for each &var; */
/*  */
/* *This uses too much disk space and SAS ondemand failed; */
/* proc sql; */
/* create table &dsdout as */
/* select &char_vars, */
/*  %do i=1 %to &nvars; */
/*    %let var=&&read_var&i; */
/* 	  %if %eval(&i<&nvars) %then %do; */
/* 		     round(&var/median(&var/gm),0.1) as &var, */
/* 			%end; */
/* 			%else %do; */
/* 		     round(&var/median(&var/gm),0.1) as &var */
/* 			%end; */
/*  %end; */
/* from &dsdout; */
/*  */
/* *Get median of &var/gm first; */
/* proc sql noprint; */
/* select  */
/*  %do i=1 %to &nvars; */
/*    %let var=&&read_var&i; */
/* 	  %if %eval(&i<&nvars) %then %do; */
/* 		     median(&var/gm), */
/* 			%end; */
/* 			%else %do; */
/* 		     median(&var/gm) into */
/* 			%end; */
/*  %end; */
/*   %do i=1 %to &nvars; */
/*    %let var=&&read_var&i; */
/* 	  %if %eval(&i<&nvars) %then %do; */
/* 		     : median4&var, */
/* 			%end; */
/* 			%else %do; */
/* 		     :median4&var */
/* 			%end; */
/*  %end; */
/* from &dsdout; */
/* *Now divide each value by its coresponding median of value divided by geomean; */
/* proc sql; */
/* update &dsdout */
/* set  */
/*  %do i=1 %to &nvars; */
/*    %let var=&&read_var&i; */
/* 	  %if %eval(&i<&nvars) %then %do; */
/* 		     &var=%sysfunc(compress(&var))/%sysfunc(compress(&&median4&var)) , */
/* 		     %if &&median4&var eq . %then %do; */
/* 		      &var=., */
/* 		     %end; */
/* 		     %else %do; */
/* 		      &var=round( &var / &&median4&var, 0.1), */
/* 		     %end; */
/* 			%end; */
/* 			%else %do; */
/* 		      &var=%sysfunc(compress(&var))/%sysfunc(compress(&median4&var)) */
/* 		     %if &&median4&var eq . %then %do; */
/* 		      &var=. */
/* 		     %end; */
/* 		     %else %do; */
/* 		      &var=round( &var / &&median4&var, 0.1) */
/* 		     %end; */
/* 			%end; */
/*  %end; */
/*  ; */
/*  */
/*  */
/*  */
/* quit; */
/* proc datasets nolist lib=work; */
/* delete &dsdout; */
/* run; */
/* proc datasets nolist; */
/* copy in=sh out=work memtype=data move; */
/* select &dsdout; */
/* run; */
/* libname sh clear; */
/*  */
/* *Need to change back the var names; */
/* data &dsdout; */
/* set &dsdout; */
/* *rename vars; */
/* rename  */
/* %do xi=1 %to &nvars; */
/*    %let var=&&read_var&xi; */
/*    _&var=&var */
/* %end; */
/* ; */
/*  */
/* *Assign 0 for missing data and overwrite the &dsdout with _&dsdout; */
/* data &dsdout; */
/* set &dsdout; */
/* array X{*}  */
/* %do vi=1 %to &nvars; */
/*   &&read_var&vi */
/* %end; */
/* ; */
/* do i=1 to dim(X); */
/*  if X{i}=. then X{i}=0; */
/* end; */
/* *gm is not included in the updated &dsdout generated by new sas codes; */
/* drop i gm; */
/* drop i tag gm; */
/* run; */
/*  */
/* options compress=no; */
/*  */
/* *Clean work lib; */
/* proc datasets nolist lib=work; */
/* delete info; */
/* run; */
/* *Delete macro variables; */
/* %delmacrovars(macro_var_rgx=median4) ; */
/* %delmacrovars(macro_var_rgx=read_var) ; */

%mend;
/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

data a;
input g $ x1-x9;
cards;
a 1 0 4 5 6 7 8 9 10
b 3 0 4 6 8 9 10 11 30
c 4 5 0 1 0 2 3 4 10
;
run;

option mprint symbolgen mlogic;
*Note: the output can be the same dsd;
%deseq_normalization(
dsdin=a,
read_vars=_numeric_,
dsdout=a_norm,
readcutoff=0,
cellcutoff=1
);
proc print data=a_norm;run;

*Alternative way to normalize long format sas data;
*in proc sql, geomean can calculated by group with:;
*exp(mean(log(var)));
data b(keep=g exp i);
set a;
array T{*} _numeric_;
do i=1 to dim(T);
   exp=T{i};
   if exp^=0 then output;
end;
run;
proc sql;
create table b as
select g,i,exp,exp/exp(mean(log(exp))) as _reads
from b 
group by g
order by g, i;
proc sql;
create table b as
select g,i,
       round(exp/median(_reads),0.1) as exp
from b
group by i
order by g,i;
proc transpose data=b out=b(drop=_name_) prefix=V;
var exp;
id i;
by g;
run;
proc print;run;
*/


 
