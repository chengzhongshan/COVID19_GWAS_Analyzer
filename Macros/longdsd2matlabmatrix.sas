%macro longdsd2matlabmatrix(dsd,var_row,var_col,data_var,value2asign4missing,dsdout,outdir4matrix);
proc sort data=&dsd;by &var_row &var_col;
proc transpose data=&dsd out=&dsdout(drop=_name_);
var &data_var;
by &var_row;
id &var_col;
run;

data &dsdout;
set &dsdout;
array x{*} _numeric_;
do i=1 to dim(x);
 if x{i}=. then x{i}=&value2asign4missing;
end;
drop i;
run;

%if %eval(&outdir4matrix^=) %then %do;
proc export data=&dsdout(keep=&var_row) outfile="&outdir4matrix/rowlabels.txt" replace
dbms=tab;putnames=no;
run;
proc export data=&dsdout(drop=&var_row) outfile="&outdir4matrix/matrix.tab" replace
dbms=tab;putnames=no;
run;
proc export data=&dsdout(drop=&var_row obs=0) outfile="&outdir4matrix/collabels.txt" replace
dbms=tab;putnames=yes;
run;
%end;


%mend;
/*Transform SAS long format data intout matrix and output into specific dir if outdir4matir is not missing;

%longdsd2matlabmatrix(dsd=inputdsd
                     ,var_row=x
                     ,var_col=y
                     ,data_var=col1
                     ,value2asign4missing=-999
                     ,dsdout=
                     ,outdir4matrix=);
*/
