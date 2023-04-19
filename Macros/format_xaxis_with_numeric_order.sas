%macro format_xaxis_with_numeric_order(dsdin,Xaxis_vars,new_Xaxis_var,Var4sorting_Xaxis,function4sorting,descending_or_not,dsdout,createdfmtname);

*If AlsoAppFun4Cols=1, will apply specific function on each row or ALL Rows (if row_keys is missing) for ALL these matched columns;
*For AlsoAppFun4Cols=1, we can not use avg but mean, because avg is going to calculate mean based on group and mean is to calculate mean of different columns;
*Should be careful to use this function to calculate mean of ALL data points.;
*Note: KeyVar4dsdout will try to catx all row_keys with ':';
%ApplyFunc_rowwide(dsdin=&dsdin
                  ,row_keys=&Xaxis_vars
                  ,KeyVar4dsdout=KeyVar4dsdout
                  ,Regex4col_vars2apply=&Var4sorting_Xaxis
				  ,SQL_Fun4apply=&function4sorting
                  ,dsdout=Sorted_dsd
                  ,AlsoAppFun4Cols=1);
%put Xaxis_vars are &Xaxis_vars;

*Add numeric grp id to each grp with the order in accordace with the summary of &var4sorting after applied for the function &function4sorting by grp;
*New variable &function4sorting will be created, which can be used to sort the new variable dataset;
*If supplying ONE or multiple vars into grp_vars4sort, a default new var combining all these vars with ':' will be created;
*which is grps_output_key;
%char_grp_to_num_grp(dsdin=Sorted_dsd,grp_vars4sort=&function4sorting KeyVar4dsdout,descending_or_not=&descending_or_not,dsdout=Sorted_dsd1,num_grp_output_name=&new_Xaxis_var);

/*catx Xaxis_vars*/
data var_labels;
set Sorted_dsd1;
*remove leading grp generated by supplied function;
grps_output_key=prxchange('s/^[^:]+://',-1,grps_output_key);
keep grps_output_key &new_Xaxis_var KeyVar4dsdout;
run;

proc sql noprint;
select count(grps_output_key), catx('','grp',count(grps_output_key)) into: vtot, : grp_v
from var_labels;
select grps_output_key into: vvgrp1 - : vv&grp_v
from var_labels;

*Print it for debugging;
%do xi=1 %to &vtot; 
   %put Apply format for &xi="&&vvgrp&xi";
%end;

*Delete previous format, otherwise the new format will not be applied;
/*
proc format lib=work fmtlib;
run;
*/

proc catalog cat=work.formats;
delete &createdfmtname..format;
run;

proc format;
value &createdfmtname 
%do i=1 %to &vtot; 
        &i="&&vvgrp&i"
%end;
;
data &dsdin;
set &dsdin;
KeyVar4dsdout=catx(':',of &Xaxis_vars);
run;

proc sql;
create table &dsdin._tmp as
select a.*,
       b.&new_Xaxis_var,
       b.grps_output_key
from &dsdin as a
left join
var_labels as b
on strip(left(a.KeyVar4dsdout))=strip(left(b.KeyVar4dsdout))
;

data &dsdout;
set &dsdin._tmp;
num_grp=&new_Xaxis_var;
/*Will change it manually outside of the macro later*/
attrib &new_Xaxis_var format=&createdfmtname..;
run;

proc sort data=&dsdout;by num_grp;run;

%mend;

/*
*Demo:;

data x;
input FileName $ FileName1 $ chr value;
cards;
a c 1 5
a d 3 4
a d 3 10
c a 2 1
d d 1 50
e f 10 100
f a 22 1000
f a 22 2000
f a 22 1500
;


*options mprint mlogic symbolgen;

*Sort with variable for xaxis;

%format_xaxis_with_numeric_order(
dsdin=x,
Xaxis_vars=FileName FileName1,
new_Xaxis_var=grp,
Var4sorting_Xaxis=value,
function4sorting=avg,
descending_or_not=1,
dsdout=tmp,
createdfmtname=Xaxis_var_label);

proc boxplot data=tmp;
plot value*grp;
run;

proc sgplot data=tmp;
scatter x=grp y=value;
run;

*/


