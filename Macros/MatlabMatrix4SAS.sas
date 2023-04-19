%macro MatlabMatrix4SAS(Matrix_File,Rowlabels_File,Collabels_File,dsd_out,Matrix2Num);

/*
%let tmp_dir = %sysfunc(getoption(work));
%let outfullpath=%str(&tmp_dir/Proc_Import_Template.sas);
%Make_Proc_Import_Code(abs_data_file_name=&Matrix_File
                         ,sas_code_file=&outfullpath
						 ,kept_variables=_all_
						 ,getnames_yes_no=No
						 ,datarow=1
                         ,dbms=tab
                         ,force2Num=&Matrix2Num
                         ,dsdoutname=&dsd_out
);
%include "&outfullpath";
*delete the temp.txt;
filename fd "&outfullpath";
data _null_;
rc=fdelete("fd");
run;
*/

*Check macro Make_Proc_Import_Code for details;
%ImportDsd_via_Proc_Import(filepath=&Matrix_File,
                                  _kept_variables=_all_,
								  _getnames_yes_no=No,
								  _datarow=1,
								  _dbms=tab,
								  _force2Num=&Matrix2Num,
                                  dsdout=&dsd_out);

/*Too slow to use the following macro
%ImportFilebyScan(file=&Matrix_File
                 ,dsdout=&dsd_out
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=0
                 ,MissingSymb=NaN
);
*/

proc import datafile="&Rowlabels_File"
dbms=tab out=rownames replace;
getnames=no;
guessingrows=1000;
run;
proc import datafile="&Collabels_File"
dbms=tab out=colnames replace;
getnames=no;
guessingrows=10000;
run;
data colnames;
set colnames;
var1=prxchange('s/[-\W]+/_/',-1,var1);
if prxmatch('/^\d/',var1) then do;
var1=cat('_',var1,'');
end;
run;

data &dsd_out;
set rownames(rename=(var1=rownames));
set &dsd_out;
run;
proc sql noprint;
create table tmp as
select name,label,format
from dictionary.columns
where libname=upper("work") and
      memname=upper("&dsd_out") and
	  memtype="DATA";
data tmp;
set tmp;
where name^="rownames";
run;

proc sql noprint;
select name into: colnames separated by ' '
from tmp;
select var1 into: newcolnames separated by ' '
from colnames;

data &dsd_out;
  set &dsd_out;
  %Rename_oldvarlist2newvarlist(&colnames, &newcolnames);
run;
%mend;


/*For matlab numeric matrix;
options mprint mlogic symbolgen;
x cd "D:\F_tmp\NewTCGAAssocRst\COAD\MatlabAnalysis\annotations";
%MatlabMatrix4SAS(Matrix_File=matrix.tab
                 ,Rowlabels_File=rowlabels.txt
                 ,Collabels_File=collabels.txt
                 ,dsd_out=Regulatory_matrix
                 ,Matrix2Num=1); 


*For character matrix;
%MatlabMatrix4SAS(Matrix_File=matrix.tab
                 ,Rowlabels_File=rowlabels.txt
                 ,Collabels_File=collabels.txt
                 ,dsd_out=Regulatory_matrix
                 ,Matrix2Num=0); 
*/

