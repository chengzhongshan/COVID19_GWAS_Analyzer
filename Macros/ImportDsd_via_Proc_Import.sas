%macro ImportDsd_via_Proc_Import(filepath,
                                  _kept_variables,
								  _getnames_yes_no,
								  _datarow,
								  _dbms,
								  _force2Num,
                                  dsdout);
*Make Linux and WIN usable filedir;
%let filepath=%sysfunc(prxchange(s/\\/\//,-1,&filepath));

%let tmp_dir = %sysfunc(getoption(work));
%let outfullpath=%str(&tmp_dir/Proc_Import_Template.sas);

%Make_Proc_Import_Code(abs_data_file_name=&filepath,
                         sas_code_file=&outfullpath,
						 kept_variables=&_kept_variables,
						 getnames_yes_no=&_getnames_yes_no,
						 datarow=&_datarow,
                         dbms=&_dbms,
                         force2Num=&_force2Num,
                         dsdoutname=&dsdout);

%include "&outfullpath";

*delete the temp.txt;
filename fd "&outfullpath";
data _null_;
rc=fdelete("fd");
run;

%mend;

/*
x cd "D:\F_tmp\NewTCGAAssocRst\COAD\MatlabAnalysis\annotations";
*Check macro Make_Proc_Import_Code for details;
*Can not use macro option mprint;
%ImportDsd_via_Proc_Import(filepath=matrix.tab,
                                  _kept_variables=_all_,
								  _getnames_yes_no=No,
								  _datarow=1,
								  _dbms=tab,
								  _force2Num=0,
                                  dsdout=x);
*/
