%macro rm_rows_gt_nmissing(
dsd=_last_,
nmissing_cutoff=1, /*Remove rows with more than or equal to 1 missing records*/
reverse=0,/*Default is 0 for removal of rows with total number missing vars >= nmissing_cutoff; 
Assign value 1 to revease the search to obtain rows with at least the specific number of non-missing values defined by the macro var nmissing_cutoff*/ 
tgt_var_type=_numeric_,/*Evaluate the total number of missing across the same type of  numeric or character variables*/
dsdout=dsd_filtered,/*Filtered dsd*/
missing_summ_dsd=missing_rate_dsd /*Output a dsd containing the missing rate for each row*/
);
%local tot_vars;
%let tot_vars=%TotVarsInDsd(&dsd,var_type=&tgt_var_type);
data &dsdout;
set &dsd;
missing_rate=cmiss(of &tgt_var_type)/&tot_vars;
data &missing_summ_dsd;
set &dsdout;
drop &tgt_var_type;
data &missing_summ_dsd;
merge &missing_summ_dsd &dsdout(keep=missing_rate);
run; 

data &dsdout;
set &dsdout(drop=missing_rate);
%if &reverse=1 %then %do;
*Keep rows with at least n columns are not missing;
if cmiss(of &tgt_var_type)<=&tot_vars-&nmissing_cutoff;
%end;
%else %do;
*Keep rows with total number of missing variables less than or equal to the provided cutoff;
if cmiss(of &tgt_var_type)<=&nmissing_cutoff;
%end;

run;

%mend;
/*Demo codes:;

*Keep rows with total number of missing variables less than or equal to the provided cutoff;
%rm_rows_gt_nmissing(
dsd=_last_,
nmissing_cutoff=1, 
reverse=0,
tgt_var_type=_numeric_,
dsdout=dsd_filtered,
missing_summ_dsd=missing_rate_dsd
);

*Keep rows with at least n columns are not missing;
%rm_rows_gt_nmissing(
dsd=_last_,
nmissing_cutoff=1, 
reverse=1,
tgt_var_type=_numeric_,
dsdout=dsd_filtered,
missing_summ_dsd=missing_rate_dsd
);

*/
