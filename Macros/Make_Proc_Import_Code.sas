

%macro Make_Proc_Import_Code(abs_data_file_name,sas_code_file,kept_variables,getnames_yes_no,datarow,dbms,Force2Num,dsdoutname);

*Excape char '\' or '/' in abs_data_file_name;
%let abs_data_file_name=%sysfunc(prxchange(s/[\\\/]/\\\//,-1,&abs_data_file_name));
%put &abs_data_file_name;

proc printto log="SAS_Import_Codes.sas" new;
run;
filename exTemp temp;
data _null_;
infile "&abs_data_file_name" lrecl=32767 firstobs=1 obs=1001;
file exTemp;
input;
put _infile_;
run;
proc import datafile=exTemp
             dbms=&dbms out=&dsdoutname(keep=&kept_variables) replace;
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
*Need to escape '\' or '/' in &abs_data_file_name;
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
   %if &force2Num %then %do;
   _infile_=prxchange('s/\$\d+\./best32/',-1,_infile_);
   _infile_=prxchange('s/\$//',-1,_infile_);
   %end;
   put _infile_;
 end;
run;
%Mend;

/*
%pgmpathname;*Get current path of running program;
%File_Head(filename="filefullpath",n=10);
%Make_Proc_Import_Code(abs_data_file_name=I:\OneKGPlinkPeds\OneKG_PlinkBed_All_Populations\ALL_chr1_OneKG_AFR.bim,
             sas_code_file=&pgmpathname.\Proc_Import_Template.sas,
			 kept_variables=var1 var2 var4 var5 var6,
			 getnames_yes_no=No,
			 datarow=1,
             dbms=tab|DLM|CSV|....,
             force2Num=0,
             dsdoutname=out);

%Better usage;

%let tmp_dir = %sysfunc(getoption(work));
%let outfullpath=%str(&tmp_dir/Proc_Import_Template.sas);
x cd "D:\F_tmp\NewTCGAAssocRst\COAD\MatlabAnalysis\annotations";
%Make_Proc_Import_Code(abs_data_file_name=matrix.tab,
                         sas_code_file=&outfullpath,
						 kept_variables=_all_,
						 getnames_yes_no=No,
						 datarow=1,
                         dbms=tab,
                         force2Num=1,
                         dsdoutname=out);

%include "&outfullpath";

*delete the temp.txt;
filename fd "&outfullpath";
data _null_;
rc=fdelete("fd");
run;

*/
