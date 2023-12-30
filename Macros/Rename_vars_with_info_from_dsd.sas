%macro Rename_vars_with_info_from_dsd(
dsdin,
var_info_dsd,
old_var_info,/*a variable containing old variable names in the dsd var_info_dsd*/
new_var_info,/*a variable containing new variable names for renaming the old variable names 
 in the dsd var_info_dsd*/
outdsd);
proc sql noprint;
select &old_var_info,&new_var_info into: old_vars separated by ' ', : new_vars separated by ' '
from &var_info_dsd;
data &outdsd;
  set &dsdin;
  %Rename_oldvarlist2newvarlist(&old_vars,&new_vars);
run;

%mend;

/*
data faminc;
  input famid faminc1-faminc12 ;
cards;
1 3281 3413 3114 2500 2700 3500 3114 -999 3514 1282 2434 2818
2 4042 3084 3108 3150 -999 3100 1531 2914 3819 4124 4274 4471
3 6015 6123 6113 -999 6100 6200 6186 6132 -999 4231 6039 6215
;
run;

proc contents data=faminc out=ftb(keep=NAME VARNUM) noprint;
run;
data ftb_new;
set ftb(rename=(Name=New_Name));
New_name="X"||New_name;
run;
proc sql;
create table var_info as
select a.*,b.New_name
from ftb as a,
     ftb_new as b
where a.varnum=b.varnum;

%Rename_vars_with_info_from_dsd(dsdin=faminc,
                               var_info_dsd=var_info,
                               old_var_info=name,
                               new_var_info=New_name,
                               outdsd=faminc_new);

proc print data = faminc_new heading=h noobs;
run;
*/
