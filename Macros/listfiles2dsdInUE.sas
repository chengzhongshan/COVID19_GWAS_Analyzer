
%macro listfiles2dsdInUE(dir,filergx,outdsd);
*Change dir into macro dir;
data _null_;
      rc=dlgcdir("&dir");
      put rc=;
run;

*For UE;
*%include "/folders/myshortcuts/zcheng/Macros/list_files.sas";
*%include "/folders/myshortcuts/zcheng/Macros/del_file_with_fullpath.sas";

*For SAS onDemand;
*%let uedir=%sysfunc(pathname(HOME))/Macros;

*%let uedir=&dir;
*%include "&uedir/list_files.sas";
*%include "&uedir/del_file_with_fullpath.sas";

*Not necessary to add the dir, as it is changed into the macro dir;
%include "list_files.sas";
%include "del_file_with_fullpath.sas";

proc printto log="&dir/printto.log" new;
run;
%list_files(&dir,&filergx);
/*Make sure to reset printto aftet the list_files;*/
proc printto;run;
proc printto log=log;run;

filename fn "&dir/printto.log";
data &outdsd;
length filename $2000.;
infile fn lrecl=2000;
input;
filename=_infile_;
if prxmatch("/&filergx/i",filename);
run;

%del_file_with_fullpath(&dir/printto.log);

%mend;

/*
*Get working dir or change default dir with dlgcdir:
*%include "%sysfunc(pathname(HOME))/Macros/listfiles2dsdInUE.sas";
*%listfiles2dsdInUE(%sysfunc(pathname(HOME))/Macros,import,test);

%include "%sysfunc(pathname(HOME))/listfiles2dsdInUE.sas";
%listfiles2dsdInUE(%sysfunc(pathname(HOME))/Macros,import,test);

*/