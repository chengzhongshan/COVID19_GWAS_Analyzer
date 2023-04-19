%macro Zscore4matrix(dsdin
,rowwide
,ByVar4rowwide
,dsdout
);

%if %eval(&rowwide=0) %then %do;
/*colwide z-score*/
proc standard data=&dsdin mean=0 std=1 out=&dsdout;
var _numeric_;
run;
%end;
%else %do;
/*row-wide z-score*/
proc transpose data=&dsdin out=&dsdin._tmp;
var _numeric_;
by &ByVar4rowwide notsorted;
run;
proc standard data=&dsdin._tmp mean=0 std=1 out=rowwide_z;
var col1;
by &ByVar4rowwide notsorted;
run;
%longdsd2matlabmatrix(dsd=rowwide_z
                     ,var_row=&ByVar4rowwide
                     ,var_col=_NAME_
                     ,data_var=col1
                     ,value2asign4missing=-999
					 ,dsdout=&dsdout
                     ,outdir4matrix=);
%end;
%mend;


/*Col-wide z-score, which is the easiest to perform;
 *No need to provide parameter for ByVar4rowwide;*/

/*
%Zscore4matrix(dsdin=x
,rowwide=0
,ByVar4rowwide=
,dsdout=z
);
*/

/*
*Row-wide z-score, which is the hardest to perform;
*Need to provide parameter for ByVar4rowwide;
*Make sure no duplicates in column of &ByVar4rowwide*/

/*
%Zscore4matrix(dsdin=x
,rowwide=1
,ByVar4rowwide=VarKeys
,dsdout=z
);
*/




