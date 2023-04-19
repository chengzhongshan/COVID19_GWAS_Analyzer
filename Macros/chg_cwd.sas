/* options mprint mlogic symbolgen xwait noxsync;*/
%macro chg_cwd(pwd,cmd);
%let go2path=%str(cd "&pwd");
 data _null_;
 call system(&go2path %str(&) &cmd);
 run;
%mend;

/*
%pgmpathname;
%put pgmpathname=&pgmpathname;

%chg_cwd(pwd=c:/,cmd=ls);

%let execpath=%qsubstr(%sysget(sas_execfilepath),1,%length(%sysget(sas_execfilepath))-
	%length(%sysget(sas_execfilename)));
%put &execpath;

%file_list(&execpath);
*/
