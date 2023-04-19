

%macro Make_Proc_Import_Code(abs_data_file_name,sas_code_file,kept_variables,getnames_yes_no,datarow,dbms);
proc printto log="SAS_Import_Codes.sas" new;
run;
filename exTemp temp;
data _null_;
infile "&abs_data_file_name" firstobs=1 obs=1001;
file exTemp;
input;
put _infile_;
run;
proc import datafile=exTemp
             dbms=&dbms out=dbSNP_ensembl(keep=&kept_variables) replace;
			 getnames=&getnames_yes_no;
			 datarow=&datarow;
			 guessingrows=1000;
run;

proc printto;run;

proc printto log=log;
run;

data _null_;
infile "SAS_Import_Codes.sas" lrecl=32767;
file "&sas_code_file";

if _n_=1 then do;
Pattern_st=prxparse("/\/\*{2,}/");
Pattern_end=prxparse("/if _ERROR_ then call symputx/");
retain Pattern_st Pattern_end;
put "/***********************************************************************";
end;

input;
_infile_=prxchange("s/^\d+\s+//",-1,_infile_);
_infile_=prxchange("s/EXTEMP/'&abs_data_file_name'/",-1,_infile_);
*Get the line num of which the contains match Pattern_st;
if (prxmatch(Pattern_st,_infile_)>0) then do;
   n_st=_n_;
end;
*Keep n for later use, otherwise, sas will delete it;
retain n_st;

*Get the last line num of which the contains match Pattern_end;
if (prxmatch(Pattern_end,_infile_)>0) then do;
    n_end=_n_;
	put _infile_;
	put "run;";
end;
*Keep n for later use, otherwise, sas will delete it;
retain n_end;

*Beware about the fact that sas read data line by line!;
*Only print rows between n_st and n_end;
*The n_end<1 is used, as n_end is eq 0 before sas reaching the n_end pattern;
if (n_st>0 and n_st<_n_ and n_end<1) then do;
   put _infile_;
 end;
run;
%Mend;
/*
%pgmpathname;*Get current path of running program;

%Make_Proc_Import_Code(abs_data_file_name=I:\SASGWASDatabase\Important_Analysis_Codes\Step 1 ensembl SQL data\variation_feature.txt,
                         sas_code_file=&pgmpathname.\Proc_Import_Template.sas,
						 kept_variables=var1 var2 var3,
						 getnames_yes_no=No,
						 datarow=1,
             dbms=tab);
*/
