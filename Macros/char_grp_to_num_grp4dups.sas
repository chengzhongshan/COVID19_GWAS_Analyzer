%macro char_grp_to_num_grp4dups(dsdin,grp_vars4sort,descending_or_not,dsdout,num_grp_output_name);
%let nvars=%numargs(&grp_vars4sort);
data &dsdout;
set &dsdin;
%if &nvars>=1 %then %do;
grps_output_key=catx(':', of &grp_vars4sort);
%end;
%else %do;
grps_output_key=&grp_vars4sort;
%end;
run;
/*All grp keys are kept!*/
*Use key instead of by in the proc sort, as unknown error occurred when using by with descending function;
%if &descending_or_not %then %do;
proc sort data=&dsdout out=&dsdout;
key grps_output_key /descending;
run;
%end;
%else %do;
proc sort data=&dsdout out=&dsdout;
key grps_output_key;
run;
%end;

data &dsdout;
set &dsdout;
retain &num_grp_output_name 0;
if first.grps_output_key then do;
 &num_grp_output_name=&num_grp_output_name+1;
 output;
end;
else do;
 output;
end;
by grps_output_key;
run;

%mend;
/*
options mprint mlogic symbolgen;

%char_grp_to_num_grp4dups(dsdin=dsd,grp_vars4sort=ase,descending_or_not=0,dsdout=x,num_grp_output_name=ngrp);

%char_grp_to_num_grp4dups(dsdin=dsd,grp_vars4sort=,descending_or_not=0,dsdout=x,num_grp_output_name=ngrp);

*If supplying ONE or multiple vars into grp_vars4sort, a default new var combining all these vars with ':' will be created;
*which is grps_output_key;


*Demo;
data x0;
input chr st end cnv type $ grp $;
cards;
1 100 300 1 a x1
1 200 400 3 a x1
1 400 500 0 b x2
1 600 800 3 b x2
1 700 800 2 c x2
;
run;
options mprint mlogic symbolgen;
%char_grp_to_num_grp4dups(
dsdin=x0,
grp_vars4sort=grp type,
descending_or_not=0,
dsdout=x,
num_grp_output_name=ngrp
);


*/
