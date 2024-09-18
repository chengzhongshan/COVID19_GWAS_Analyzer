%macro rm_cols_gt_nmissing(
dsd,/*Input data set; it can be subsetted if not all numeric or character vars 
are targetted before supplying to the macro*/
var_type,	/*_numeric_ or _character_; 
if only specific numeric or character vars are targeted, please subset the input dsd 
based on specific variable names*/
missing_summary=missing_summ_dsd, /*Output a dataset containg the NMissing and missing % for all targetted vars*/
missing_N_cutoff=3, /*When reverse=0, remove the var with missing n >= the cutoff; 
when reverse=1, keep the var with at least the cutoff of number of non-missing value*/
reverse=0,/*Remove or keep var based on the missing_N_cutoff*/
filtered_dsdout=filtered_dsdout, /*The sas dataset after filtering with the above criteria*/
print_missing_summary=0 /*Print out the missing summary dataset*/
);

%local nvars isnumeric vi colvar;
data _&dsd._;
set &dsd;
keep &var_type;

data _&dsd._1;
set &dsd;
drop &var_type;
run;

%let nvars=%TotVarsInDsd(_&dsd._,var_type=&var_type);

%if "&var_type"="_numeric_" %then %do;
 %let isnumeric=1;
%end;
%else %do;
 %let isnumeric=0;
 %end;

%getnumorcharvars4dsd(indsd=_&dsd._,outdsd=vars_list,numeric=&isnumeric);
proc sql noprint;
select name into: colvars separated by ' '
from vars_list;
select count(*) into: tot_rows 
from _&dsd._;

*Note: do not add sas end character at the end of macro function str inside the proc sql statement;
*otherwise, the sas macro codes will add the sas end character into the proc sql codes;
*leading to errors as proc sql can not read the complete codes!;
*Additionally, if a column is with all missing value, the function count(&colvar) will be assigned with the missing value ".";
*This is why we need to have the tot_rows to replace the count(&colvar) in the proc sql statement;

proc sql noprint;
create table &missing_summary as
select 
%do vi=1 %to &nvars;
    %let colvar=%scan(&colvars,&vi,%str( ));
    %str(nmiss(&colvar) as NM4&colvar, nmiss(&colvar)/&tot_rows as MR4&colvar, &tot_rows as tot4&colvar)
    %if &vi<&nvars %then %do;
		        %str( ,)
     %end;
     %else %do;
				    %str(from _&dsd._;)
     %end;
%end;

proc transpose data=&missing_summary out=_&missing_summary._1(rename=(_name_=Varname col1=Nmissing));
var NM4:;
data _&missing_summary._1;
set _&missing_summary._1;
Varname=prxchange('s/^(MR|NM)4//',-1,Varname);
run;

proc transpose data=&missing_summary out=_&missing_summary._2(rename=(_name_=Varname col1=MissingRate));
var MR4:;
data _&missing_summary._2;
set _&missing_summary._2;
Varname=prxchange('s/^(MR|NM)4//',-1,Varname);
run;

proc transpose data=&missing_summary out=_&missing_summary._3(rename=(_name_=Varname col1=Total));
var tot4:;
data _&missing_summary._3;
set _&missing_summary._3;
Varname=prxchange('s/^(MR|NM|tot)4//',-1,Varname);
run;
data 	_&missing_summary._2;
merge _&missing_summary._2 _&missing_summary._3;
run;

proc sql;
create table &missing_summary as 
select *,&tot_rows as tot_counts,&missing_N_cutoff as Missing_Cutoff,

				 %if &reverse=1 %then %do;
           %str(Total-Nmissing>=&missing_N_cutoff as LE_Missing_Cutoff)
         %end;
         %else %do;
           %str(Nmissing>=&missing_N_cutoff as GE_Missing_Cutoff)
          %end;

from _&missing_summary._1
natural join
_&missing_summary._2
;

%if &print_missing_summary=1 %then %do;
title "Missing rate summary for the input dataset &dsd";
proc print;run;
title;
%end;

data _&missing_summary._;
set &missing_summary;
%if &reverse=1 %then %do;
  if 	LE_Missing_Cutoff=0 then delete;
%end;
%else %do;
  if 	GE_Missing_Cutoff=1 then delete;
%end;
run;


proc sql noprint;
select varname into: kept_vars separated by ' '
from _&missing_summary._;
%if %symexist(kept_vars)=0 %then %do;
					 %put After filtering, no column vars included in the dataset _&missing_summary._;
           %abort 255;
%end;
data &filtered_dsdout;
set _&dsd._;
keep &kept_vars;
run;


*Add back these vars that are not the target variable type;
data &filtered_dsdout;
merge &filtered_dsdout _&dsd._1;
run;

/*proc datasets lib=work nolist;*/
/*delete 	_&missing_summary: _&dsd._*/
/*            Vars_list _&dsd._1;*/
/*run;*/

%mend;
/*Demo:

data Y71;
input a b;
cards;
. .
1 .
2 .
3 .
;

options mprint mlogic symbolgen;

*All vars with less than 3 missing values will be kept in the final dataset;
%rm_cols_gt_nmissing(
dsd=Y71,
var_type=_numeric_,
missing_summary=missing_summ_dsd, 
missing_N_cutoff=3, 
reverse=1,
filtered_dsdout=filtered_dsdout 
);

*All vars with more than 3 missing values will be excluded in the final dataset;
%rm_cols_gt_nmissing(
dsd=Y71,
var_type=_numeric_,
missing_summary=missing_summ_dsd, 
missing_N_cutoff=3, 
reverse=0,
print_missing_summary=1,
filtered_dsdout=filtered_dsdout 
);

*/
