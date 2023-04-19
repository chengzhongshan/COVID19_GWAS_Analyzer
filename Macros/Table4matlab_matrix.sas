%macro Table4matlab_matrix(dsdin,col4matrix_rowlabels,fixedmissingvalue,outdir);
%if "&fixedmissingvalue"="" %then %do;
%let fixedmissingvalue=-1000;
%end;

data tmp;
set &dsdin;
array X{*} _numeric_;
do i=1 to dim(X);
 if X{i]=. then X{i}=&fixedmissingvalue;
end;
drop i;
run;

proc export data=tmp(keep=&col4matrix_rowlabels) outfile="&outdir/rowlabels.txt" replace
dbms=tab;putnames=no;
run;

/*Doesn't work if we use drop command in the export procedure*/
data tmp;
set tmp;
keep _numeric_;
run;

proc export data=tmp(obs=0) outfile="&outdir/collabels.txt" replace
dbms=tab;putnames=yes;
run;

proc export data=tmp outfile="&outdir/matrix.tab" replace
dbms=tab;putnames=no;
run;

%mend;

