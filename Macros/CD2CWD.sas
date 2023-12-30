%macro CD2CWD;

%let filefullpath=%sysget(sas_execfilepath);
*If the above failed in Linux, the following will rescue the procedure;
%if %length(&filefullpath)=0 %then %let filefullpath=&_sasprogramfile;

%let cwd=%qsubstr(
&filefullpath,
1,
%length(&filefullpath)-1-%length(%scan(&filefullpath,-1,"\/"))
);

%put Current working directory is:;
%put &cwd;
/*Change to workding directory*/

/*X cd "&cwd";*/
*The above can not be executed successfully in SAS OnDemand for Academics, since the x command is turned off;
data _null_;
_rc_=dlgcdir("&cwd");
run;

%put Now the working directory is changed into the above directory;
%mend;

/*Demo codes:;

%CD2CWD;

*/

