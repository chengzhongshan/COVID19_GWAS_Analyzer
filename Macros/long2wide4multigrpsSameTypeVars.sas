%macro long2wide4multigrpsSameTypeVars(
/*Note: this macro is handy when there are multiple target numeric or characteric variables needs to be transposed to rowwide;
*Tranditional transpose procedure usually handle one type of variable to rowwide by other group variables;
*But this macro can abtain wide format table for multiple variables at rowwide at the same time by other group variables;
*The key macro parameter to represent these multiple variables is "SameTypeVars";

Note: if the maximum length of grp_vars >32, it is suggested to set ShortenColnames=1
In case of tranposing a table by swtiching rows into columns, please first transpose the table
into long format dataset, and then run this macro to change it into a wide table!
*/
long_dsd, 
outwide_dsd,
grp_vars=,/*If grp_vars and SameTypeVars are overlapped,
the macro will automatically only keep it in the grp_vars; 
grp_vars can be multi vars separated by space, which 
can be numeric and character*/
subgrpvar4wideheader=,/*This subgrpvar will be used to tag all transposed SameTypeVars 
in the wide table, and the max length of this var can not be >32!*/
dlm4subgrpvar=.,/*string used to split the subgrpvar using the SCAN function if it is too long;
because SCAN will treat any of these supplied characters as delemeters to separate the string,
it is thus important to use a special char that will not be matched with any character in the 
string, such as #, to keep the string unchanged by supplying value 1 to the following macro var*/
ithelement4subgrpvar=1,/*Keep the nth splitted element of subgrpvar and use it for tag 
in the final wide table*/
SameTypeVars=_numeric_, /*These same type of vars will be added with subgrp tag in the 
final wide table; Make sure they are either numberic or character vars and not 
overlapped with grp_vars and subgrpvar!*/
ShortenColnames=0,/*Replace long headers for these transposed variables in the final rowwide table with numberic names, such as V1, V2, V3, ..., Vn;
Too match with original group vars used to generate these header names, please check the sas dataset wide_ids_lookup!*/
PutGrpVarsAtEndOfTable=0,/*When the ShortenColnames is 1, it is possible to put the grp_vars at the beginning or the end of the final table*/
tot_wide_ids_cutoff=2000,/*If more than the number of combined grp_vars*num_of_SameTypeVars, short colnames,such as V1, V2,..., Vn, will be used in the final table*/
AllowedWideIDLength=20,/*If the length of wide_ids (combined grp_vars and SameTypeVars) longer than 20, the above numeric colnames will be used*/
debug=0, /*print the first 2 records for the final wide format dsd*/
rm_rows_with_all_missing=0,/*Remove rows with all missing values*/
missing_rows_type=_numeric_,	/*target row type, such as _numeric_ or _character_, subjected to remove with all missing value*/
rm_cols_with_all_missing=0,/*Remove columns with all missing values*/
missing_columns_type=_numeric_	/*target column type, such as _numeric_ or _character_, subjected to remove with all missing value*/
/*Note: the removal of rows or columns with all missing only tested for _numeric_ matrix, and for _character_ matrix, it might have some issue!*/
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
retain max_wideids_len 0;
*Note: _wide_ids_ is the original wide_ids that is not modified by prxchange and keeps the non-words within it;
length _wide_ids_ wide_ids :$500.;
set &long_dsd._1st_trans end=eof;
*When the delemiter is not right, the following codes can be used to debug;
/*_tmp_0=&subgrpvar4wideheader;*/
/*_tmp_0=scan(&subgrpvar4wideheader,&ithelement4subgrpvar,"&dlm4subgrpvar");*/
/*_tmp_=trim(left(scan(&subgrpvar4wideheader,&ithelement4subgrpvar,"&dlm4subgrpvar")));*/
_wide_ids_=trim(left(vars))||"_"||trim(left(scan(&subgrpvar4wideheader,&ithelement4subgrpvar,"&dlm4subgrpvar")));
*As the wide_ids will be used by SAS as colnames in the transposed table, SAS will automatically replace space and other none word, such as *, +, -, into _;
*It is necessary to ensure these wide_ids do not have duplicates by groups, otherwise, the transpose procedure will faile;
wide_ids=prxchange('s/[\W ]+/_/',-1,trim(left(_wide_ids_)));
max_wideids_len=max(max_wideids_len,length(wide_ids));
if eof then call symputx('Max_wideids_len',max_wideids_len);
run;
/*%abort 255;*/
*Determine how many unique wide_ids;
*If too many wide_ids, it is necessary to replace these ids by combination of "V" and group numbers;
proc sql noprint;
create table wide_ids_lookup as
select 	 monotonic() as num_ord, 
catx('','V',put(monotonic(),best32.)) as numgrp, 
wide_ids, 
_wide_ids_
from (
	select distinct wide_ids,_wide_ids_
  from  &long_dsd._1st_trans
);
select count(*) into: tot_wide_ids
from wide_ids_lookup;

%put The maximum length for your wide_ids is &Max_wideids_len;
%if &Max_wideids_len>&AllowedWideIDLength %then %do;
   %put Warning: lease consider to modify the input group variables that used to make the wide_ids;
   %put Warning: and ensure that no duplicate wise_ids will be generated for the combination of different group vars;
%end;

%if &ShortenColnames=1 or (&tot_wide_ids>&tot_wide_ids_cutoff and &Max_wideids_len>&AllowedWideIDLength) %then %do;

    %put There are %left(&tot_wide_ids) wide_ids and the maximum length for it is &Max_wideids_len;
    %put To prevent the final table with too long headers, we will arbitrarily use short wide_ids with numbers, such as V1, V2, ..., Vn!;
    %put Please use the dataset wide_ids_lookup to lookup the original headers in later analysis;

     proc  sql;
     create table &long_dsd._1st_trans  as
     select *
     from &long_dsd._1st_trans 
     natural join
     wide_ids_lookup;

     data &long_dsd._1st_trans;
     set &long_dsd._1st_trans(drop=wide_ids _wide_ids_ num_ord);
     rename numgrp=wide_ids;
     run;

%end;


*Check duplicate wide_ids before transposing the tabel;
data &long_dsd._1st_trans;
set &long_dsd._1st_trans;
*Ensure the longest id of wide_ids not exceeding the limit of variable length defined by SAS in proc tranpose;
*This is probamatic, as some different elements may have the same strings for the first 32 chars;
*The same issue will occur when extracting the last 32 chars; 
*if length(wide_ids)>32 then wide_ids=substr(wide_ids,1,32);
%if &ShortenColnames=0 %then %do;
if  length(wide_ids)>32 then wide_ids=substr(wide_ids,1,32);
%end;
run;


proc sort data=&long_dsd._1st_trans out=&long_dsd._1st_trans nodupkeys dupout=dups;
by &grp_vars wide_ids;
run;

%if %totobsindsd(work.dups)>0 %then %do;
*Get these original duplicate wide ids, including _wide_ids_1 and _wide_ids_2;
proc sql;
create table dups(drop=values rename=(_wide_ids_=_wide_ids_1)) as
select *
from &long_dsd._1st_trans 
natural join
dups(keep=&grp_vars wide_ids _wide_ids_ rename=(_wide_ids_=_wide_ids_2))
;
%end;
%else %do;
 %put No duplicates in the data set &long_dsd._1st_trans;
%end;

%if %rows_in_sas_dsd(test_dsd=work.dups) > 0 %then %do;
            title "First 10 obs of duplicate wide ids in the sas dataset dups";
			proc print data=dups(obs=10);run;
           %put Error: there are duplicate records for the two group variables, &grp_vars and wide_ids, that are used for proc transpose;
            %put Please check the dataset dups to evaluate these wide_ids, and further modification for the input group variables are needed to have the above two unique groups for proc transpose!;
            %put To address the issue, just change the value the macro var ShortenColnames from 0 to 1!;
           %abort 255;
%end;

*Now transpose the new dsd into wide dsd;
proc sort data=&long_dsd._1st_trans;by &grp_vars wide_ids;
proc transpose data=&long_dsd._1st_trans out=&outwide_dsd;
var values;
id wide_ids;
by &grp_vars;
run;


data &outwide_dsd;
set &outwide_dsd;
drop _name_;
run;
proc sql noprint;
drop table &long_dsd._1st_trans;
drop table &long_dsd._uniq;
quit;

*Reorder the colnames, such as V1, V2, ..., Vn;
%if &ShortenColnames=1 or (&tot_wide_ids>&tot_wide_ids_cutoff and &Max_wideids_len>&AllowedWideIDLength) %then %do;
   %put The macro will re-order the column names for these vars, such as V1, V2, ..., Vn;
		proc sql noprint;
    select numgrp into: ordered_colnames separated by ' '
    from wide_ids_lookup
    order by num_ord;

    data &outwide_dsd;
    %if &PutGrpVarsAtEndOfTable=1 %then %do;
    retain &ordered_colnames &grp_vars;
    %end;
    %else %do;
    retain &grp_vars &ordered_colnames;
     %end;
    set  &outwide_dsd;
    run;

%end;

**************************************Remove missing rows and columns in the matrix**************************;
%if &rm_rows_with_all_missing=1 %then %do;
%rm_rows_gt_nmissing(
dsd=&outwide_dsd,
nmissing_cutoff=1, /*Remove rows with more than or equal to 1 missing records*/
reverse=1,/*Default is 0 for removal of rows with total number missing vars >= nmissing_cutoff; 
Assign value 1 to revease the search to obtain rows with at least the specific number of non-missing values defined by the macro var nmissing_cutoff*/ 
tgt_var_type=&missing_rows_type,/*Evaluate the total number of missing across the same type of  numeric or character variables*/
dsdout=&outwide_dsd,/*Filtered dsd*/
missing_summ_dsd=missing_rate_dsd /*Output a dsd containing the missing rate for each row*/
);
%end;
%if &rm_cols_with_all_missing=1 %then %do;
%rm_cols_gt_nmissing(
dsd=&outwide_dsd,/*Input data set; it can be subsetted if not all numeric or character vars 
are targetted before supplying to the macro*/
var_type=&missing_columns_type,	/*_numeric_ or _character_; 
if only specific numeric or character vars are targeted, please subset the input dsd 
based on specific variable names*/
missing_summary=missing_summ_dsd, /*Output a dataset containg the NMissing and missing % for all targetted vars*/
missing_N_cutoff=1, /*When reverse=0, remove the var with missing n >= the cutoff; 
when reverse=1, keep the var with at least the cutoff of number of non-missing value*/
reverse=1,/*Remove or keep var based on the missing_N_cutoff*/
filtered_dsdout=&outwide_dsd, /*The sas dataset after filtering with the above criteria*/
print_missing_summary=0 /*Print out the missing summary dataset*/
);
%end;


%if &debug=1 %then %do;
title "First 2 records for the final transposed data set &outwide_dsd";
proc print data=&outwide_dsd(obs=2);
run;
%end;
title;

%mend;

/*Demo:;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname D '/home/cheng.zhong.shan/data';
libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';


*This is demo to  filter target values that subject to transpose with specific cutoff;
*which is better than the use of two sas macros to remove rows and columns with all missing in the final table;
*Note: this is only applicable to a longform dsd by two group variables!;
%filter_longform_dsd4matrix(
 dsdin=tops1,
 var4matrix_row=gene, 
 var4matrix_col=tissue, 
 value_var4matrix=pvalue,
 value_cutoff_fun=min,
 value_cutoff=0.05,
 cutoff_condition= <, 
 dsdout=tops2
);

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

*Note: this macro is handy when there are multiple target numeric or characteric variables needs to be transposed to rowwide;
*Tranditional transpose procedure usually handle one type of variable to rowwide by other group variables;
*But this macro can abtain wide format table for multiple variables at rowwide at the same time by other group variables;
*The key macro parameter to represent these multiple variables is "SameTypeVars";


%long2wide4multigrpsSameTypeVars(
long_dsd=a,
outwide_dsd=widedsd,
grp_vars=rsid chr,
subgrpvar4wideheader=dsd,
dlm4subgrpvar=.,
ithelement4subgrpvar=2,
SameTypeVars=_numeric_,
ShortenColnames=0,
PutGrpVarsAtEndOfTable=0,
tot_wide_ids_cutoff=2000,
AllowedWideIDLength=20,
debug=0
);

*/


