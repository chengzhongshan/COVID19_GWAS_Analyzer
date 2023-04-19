*This macro is replace by deseq_normalization;
*as the old one takes too much resource and memory;
%macro deseq_normalization_old(
dsdin,
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

data &dsdout (keep=n exp i);
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
   exp=T{i};
   if exp>0 and tag>=&cellcutoff then output;
end;
run;
data rownames;
set &dsdin(keep=_character_);
n=_n_;
run;
proc sql;
create table rownames(drop=n) as
select a.*
from rownames as a,
     (select unique(n) as n from &dsdout (keep=n)) as b
     where a.n=b.n
order by n;
*Implement the calculation of geomean and normalization into datasetp;
*as proc sql is very memory intensive;
proc sql;
create table &dsdout as
select *,exp/exp(mean(log(exp))) as _exp
from &dsdout
group by n;
/* group by &char_vars; */
/* SAS failed as out of memory! */
/* order by &char_vars, i; */
proc sql;
create table &dsdout as
select n,i,
/*        round(exp/median(_exp),0.1) as exp */
exp/median(_exp) as exp format=12.0
from &dsdout
group by i;
/* SAS failed as out of memory! */
/* order by &char_vars, i; */
proc sort data=&dsdout;by n;run;
proc transpose data=&dsdout out=&dsdout(drop=_name_) prefix=V;
var exp;
id i;
by n;
/* by &_char_vars_; */
run;
*add rownames back to the table;
*make missing value as 0;
data &dsdout;
set &dsdout(drop=n);
array N{*} _numeric_;
do i=1 to dim(N);
  if N{i}=. then N{i}=0;
end;
drop i;

data &dsdout;
set &dsdout;
set rownames;
run;

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
readcutoff=3,
cellcutoff=5
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
select g,i,exp,exp/exp(mean(log(exp))) as _exp
from b 
group by g
order by g, i;
proc sql;
create table b as
select g,i,
       round(exp/median(_exp),0.1) as exp
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


 
