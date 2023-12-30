%macro number_rows_by_grp(
dsdin,
grp_var,
num_var4sort,
descending_or_not,
dsdout
);

%if &descending_or_not %then %do;
proc sort data=&dsdin;
key &grp_var &num_var4sort/ descending;
run;
%end;
%else %do;
proc sort data=&dsdin;
key &grp_var &num_var4sort;
run;
%end;

proc sort data=&dsdin;by &grp_var;
run;

data &dsdout;
retain ord 0;
set &dsdin;
if first.&grp_var then do;
 ord=1;output;
end;
else if not last.&grp_var then do;
 ord=ord+1;output;
end;
else if last.&grp_var then do;
 ord=ord+1;output;
 ord=0;
end;
by &grp_var;
run;

%if &descending_or_not %then %do;
proc sort data=&dsdout;
key &grp_var &num_var4sort / descending;
run;
%end;
%else %do;
proc sort data=&dsdout;
by &grp_var &num_var4sort;
run;
%end;

%mend;
/*
options mprint mlogic symbolgen;
*Note: grp_var will be used to group rows and num_var4sort will be used to order these rows;
%number_rows_by_grp(dsdin=dsd,grp_var=cancer,num_var4sort=ase,descending_or_not=0,dsdout=x);
*/
