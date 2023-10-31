%macro long2wide4multigrpsSameTypeVars(
long_dsd,
outwide_dsd,
grp_vars=,/*If grp_vars and SameTypeVars are overlapped,
the macro will automatically only keep it in the grp_vars; 
grp_vars can be multi vars separated by space, which 
can be numeric and character*/
subgrpvar4wideheader=,/*This subgrpvar will be used to tag all transposed SameTypeVars 
in the wide table, and the max length of this var can not be >32!*/
dlm4subgrpvar=.,/*string used to split the subgrpvar if it is too long*/
ithelement4subgrpvar=2,/*Keep the nth splitted element of subgrpvar and use it for tag 
in the final wide table*/
SameTypeVars=_numeric_, /*These same type of vars will be added with subgrp tag in the 
final wide table; Make sure they are either numberic or character vars and not 
overlapped with grp_vars and subgrpvar!*/
debug=0 /*print the first 2 records for the final wide format dsd*/
);
%let ngvars=%sysfunc(countc(&grp_vars,%str( )));
%let ngvars=%eval(&ngvars+1);

%if "&SameTypeVars"="_numeric_" %then %do;
%get_num_or_char_vars4dsd(indsd=&long_dsd,outdsd=info,numeric=1);
proc sql noprint;
select name into: SameTypeVars separated by ' '
from info
where name not in (%quotelst(&grp_vars));
%put All numeric vars not overlapped with your grp vars are:;
%put &SameTypeVars;
%end;

%else %if "&SameTypeVars"="_character_" %then %do;
%get_num_or_char_vars4dsd(indsd=&long_dsd,outdsd=info,numeric=0);
proc sql noprint;
select name into: SameTypeVars separated by ' '
from info
where name not in (%quotelst(&grp_vars));
%put All character vars not overlapped with your grp vars are:;
%put &SameTypeVars;
%end;


*first, sort the input long dsd by grp vars;
*Only unique combinations of grp vars and subgrpvar4wideheader will be keep in the input dsd;
proc sort data=&long_dsd out=&long_dsd._uniq nodupkeys;by &grp_vars &subgrpvar4wideheader;
*Note: the where condition will exclude records with any missing values across the grp vars;

proc transpose data=&long_dsd._uniq
/*This filter only works for missing character vars
as prxmatch requires to have character input at the 2nd parameter;
*/
/* ( */
/* where=( */
/* %do i=1 %to &ngvars; */
/*    %if &i<&ngvars %then %do; */
/*       (not prxmatch('/^(\s*|\.)$/',%scan(&grp_vars,&i,%str( ))) ) and  */
/*    %end; */
/*    %else %do; */
/*       (not prxmatch('/^(\s*|\.)$/',%scan(&grp_vars,&i,%str( ))) ) */
/*    %end; */
/* %end; */
/*  ) */
/* )  */

out=&long_dsd._1st_trans(rename=(_name_=vars col1=values));
variable &SameTypeVars;
by &grp_vars &subgrpvar4wideheader;
run;
*Now link vars and subgrpvar4wideheader as a single var, which will be subjected to transpose again;
data &long_dsd._1st_trans (drop=&subgrpvar4wideheader vars);
length wide_ids $500.;
set &long_dsd._1st_trans;
wide_ids=trim(left(vars))||"_"||trim(left(scan(&subgrpvar4wideheader,&ithelement4subgrpvar,"&dlm4subgrpvar")));
run;


*Now transpose the new dsd into wide dsd;
proc sort data=&long_dsd._1st_trans;by &grp_vars wide_ids;
proc transpose data=&long_dsd._1st_trans out=&outwide_dsd;
var values;
id wide_ids;
by &grp_vars;
run;
/* %abort 255; */

data &outwide_dsd;
set &outwide_dsd;
drop _name_;
run;
proc sql noprint;
drop table &long_dsd._1st_trans;
drop table &long_dsd._uniq;
quit;

%if &debug=1 %then %do;
title "First 2 records for the final transposed data set &outwide_dsd";
proc print data=&outwide_dsd(obs=2);
run;
%end;

%mend;

/*Demo:;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname D '/home/cheng.zhong.shan/data';
libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

*Use previously downloaded data by the codes following the current codes;
proc print data=D.hgi_jak2_signals noobs;
where rsid in ('rs17425819' 'rs59384377' 'rs527982744' 'rs7850484');
%print_nicer;
run;
data a;
set D.hgi_jak2_signals;
_chr_=put(chr,2.);
where rsid in ('rs17425819' 'rs59384377' 'rs527982744' 'rs7850484');
run;
%debug_macro;
%long2wide4multigrpsSameTypeVars(
long_dsd=a,
outwide_dsd=widedsd,
grp_vars=rsid chr,
subgrpvar4wideheader=dsd,
dlm4subgrpvar=.,
ithelement4subgrpvar=2,
SameTypeVars=_numeric_
);

*/


