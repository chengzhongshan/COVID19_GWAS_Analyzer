%macro dup_rows_by_grp(dsdin,grp_var,num_var4sort,desending_or_not,dsdout);

%if &desending_or_not %then %do;
proc sort data=&dsdin;
by &grp_var DESCENDING &num_var4sort;
run;
%end;
%else %do;
proc sort data=&dsdin;
by &grp_var &num_var4sort;
run;
%end;


data &dsdout;
retain ord grp 0;
set &dsdin;
if first.&grp_var then do;
 grp=grp+1;
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
%mend;

/*
options mprint mlogic symbolgen;
*Note: grp_var and num_var4sort will be used to find dups and number it;
%dup_rows_by_grp(dsdin=dsd,grp_var=cancer,num_var4sort=ase,desending_or_not=0,dsdout=x);
*/

