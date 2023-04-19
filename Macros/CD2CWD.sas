%macro CD2CWD;

%let filefullpath=%sysget(sas_execfilepath);
%let cwd=%qsubstr(
&filefullpath,
1,
%length(&filefullpath)-1-%length(%scan(&filefullpath,-1,"\/"))
);

%put Current working directory is:;
%put &cwd;
/*Change to workding directory*/
X cd "&cwd";
%mend;
