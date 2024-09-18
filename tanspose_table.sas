%macro tanspose_table(
indsd=, /*A table with unique rownames and multiple variables for transposing into row-wide*/
rowname_var=,/*a variable name in the input data set to be transposed into column-wide;
Only unique rownames will be kept for transposing*/
column_vars=_numeric_,/*A list of variables that are subjected to transposing*/
outdsd=out /*Final tranposed table with original rownames as column names and column names as rownames*/
);

proc sort data=&indsd nodupkeys;
by &rowname_var;
run;
proc transpose data=&indsd out=&outdsd(rename=(_name_=rownames));
var &column_vars;
id &rowname_var;
run;

proc contents data=&outdsd out=_tmp_ noprint;run;
data _null_;
set _tmp_;
if NAME="_LABEL_" then do;
call symputx('label_exist',1);
end;
run;

proc datasets lib=work nolist;
delete _tmp_;
run;

%if not %symexist(label_exist) %then %let label_exist=0;

*Not sure why the macro Check_VarnamesInDsd failed in the proc contents section;
/*%let var_exist=%Check_VarnamesInDsd(indsd=&outdsd,Rgx=.,exist_tag=HasVar);*/
/*%put &HasVar;*/
/*%abort 255;*/

%if &label_exist=1 %then %do;
data &outdsd;
set &outdsd;
drop _label_;
run;
%end;

%mend;

/*Demo codes:;
data x;
set sashelp.cars(obs=10);
keep model _numeric_;
run;
%debug_macro;
%tanspose_table(
indsd=x,
rowname_var=model,
column_vars=_numeric_,
outdsd=out
);

*/


