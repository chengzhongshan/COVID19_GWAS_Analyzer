%global var_type;
%macro check_var_type(dsdin,var_rgx);
proc contents data=&dsdin out=&dsdin._fmt noprint;
run;
proc sql noprint;
select distinct(TYPE) into: var_type separated by '|'
from &dsdin._fmt
where prxmatch("/&var_rgx/i",NAME);

%put The types of variables matched with regular expression &var_rgx in dsd &dsdin are:;
%put &var_type;

%mend;

*Demo:;
/*
data x;
input FileName $ FileName1 $ chr value;
cards;
a c 1 5
a d 3 4
c a 2 1
d d 1 50
e f 10 100
f a 22 1000
;
*Note: will create a global var: fmt, which can be used in other macro;
%check_var_type(
dsdin=x,
var_rgx=FileName
);

%put &var_type;

*/

