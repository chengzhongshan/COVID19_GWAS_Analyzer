
%macro importfilewithlongheader(
filename,
dlm4file,
startrow4read,
headerrow,
outdsd,
debug);

/*%let filename=FB63912.csv;*/
/*%let dlm4file=',';*/
/*%let startrow4read=2;*/
/*%let headerrow=1;*/
/**/


/*Import data without header*/
%if &debug=1 %then %do;
options obs=10;
%end;

proc import datafile="&filename" dbms=dlm out=dsd replace;
getnames=no;
datarow=&startrow4read;
delimiter=&dlm4file;
guessingrows=10000;
/*make sure not guess all rows with max, as sas will run forever when the file is too large*/
run;

%if &debug=1 %then %do;
options obs=max;
%end;

/*Guess header and modified it*/
/*The following code failed when the total length of lines >32767;*/

/*data header;*/
/*infile "&filename" dsd dlm=&dlm4file lrecl=32767 firstobs=&headerrow obs=&headerrow;*/
/*input;*/
/*Calcuate total number of vars*/
/*if (_n_=1) then do;*/
/* i=1;*/
/* do while(scan(_infile_,i,&dlm4file) ne "");*/
/*  Varname=scan(_infile_,i,&dlm4file);*/
/*  output;*/
/*  i=i+1;*/
/* end;*/
/*end;*/
/*run;*/

data header;
length varname $32.;
infile "&filename" dsd dlm=&dlm4file firstobs=&headerrow obs=&headerrow;
input varname @@;
/*Calcuate total number of vars*/
run;

proc sql noprint;
select count(*) into: nvar_header 
from header;
quit;

*Get number of vars in the dsd;
%obsnvars(work.dsd);

%if &nvar ^= &nvar_header %then %do;
  %put There are different number of vars in the header and proc import generated dataset;
		%put the header has &nvar_header columns, but the dsd has &nvars columns!;
		%abort 255;
%end;

/*Try to reduce the length of column name >32*/

data header1;
set header;
OldVarname=Varname;
Old_length=length(Varname);
Varname=prxchange('s/(\s|_|\+|\-|\#|\%|\(|\)|\[|\])//',-1,Varname); /*remove these special chars*/
if Old_length>32 then do;
  New_length=length(Varname);
  if New_length>32 then do;
     Varname=substr(Varname,1,16)||substr(Varname,New_length-15,16);
	 New_length=length(Varname);
  end;
end;
else do;
 New_length=Old_length; 
end;
if New_length<Old_length and Old_length>32 then do;
   modified=2;/*Some characters were removed and keep the length as 32*/
end;
else if New_length<Old_length and Old_length<=32 then do
   modified=1;/*Some spaces were removed*/
end;
else do;
  modified=0;/*No change*/
end;
run;
/*Check whether there are duplicated column names*/
proc sort data=header1 nodupkeys out=nodupheader dupout=dupheaders;
by Varname;
run;

proc sql noprint;
select count(*) into: tot_newvars
from nodupheader;
select count(*) into: tot_oldvars
from header1;

%if &tot_newvars=&tot_oldvars %then %do;
  title "These vars were modified to make its length less than 32 chars";
  proc print data=nodupheader(where=(old_length>new_length));run;
%end;
%else  %do;
  title "After modification,these are duplicated vars!";
  proc print data=dupheaders;run;
  %put Kill sas as there are duplicated vars even after modification;
  %abort 255;
%end;

proc contents data=dsd noprint out=dsd_vars(keep=NAME);run;
data dsd_vars;
set dsd_vars;
label Name="OldVarInTable";
i=substr(Name,4,length(Name))+0;
run;
proc sql;
create table var_info as
select a.*,b.Name as OldVarInTable
from nodupheader as a,
     dsd_vars as b
where a.i=b.i
order by i;

%Rename_vars_with_info_from_dsd(dsdin=dsd,
var_info_dsd=var_info,
old_var_info=OldVarInTable,
new_var_info=VarName,
outdsd=&outdsd
);

/*Check whether some vars are not renamed successfully*/
proc contents data=&outdsd out=updatedvar noprint;run;
proc print data=updatedvar(where=(name contains 'VAR'));run;

%mend;


/*Demo:
x cd "C:\Users\Sam\Downloads";

*This macro can be used to import data with header on different rows;

%importfilewithlongheader(filename=FB63912.csv,
dlm4file=',',
startrow4read=2,
headerrow=1,
outdsd=finaldsd
debug=1
);

*/


