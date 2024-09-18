
%macro importallmacros(/*Note: multiple dirs can only be separated by blank space and put in a single line!*/
MacroDir=/zcheng/Macros ~/shared/Macros ~/SAS-Useful-Codes/Macros /LocalDisks/F/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros,
fileRgx=.sas,
verbose=0);

%put Macro Dir is &MacroDir;
%put Your system is &sysscp;

%let ndirs=%sysfunc(countc(&MacroDir,' '))+1;

%if &verbose=0 %then %do;
options nonotes;
%end;


%do di=1 %to &ndirs;
%let _Macrodir=%scan(&MacroDir,&di,' ');
%if %sysfunc(prxmatch(/WIN/,&sysscp)) %then %do;
 filename M&di pipe "dir &_MacroDir";
 data tmp_&di;
 length filename $2000.;
 infile M&di lrecl=32767;
 input;
 filename=_infile_;
 filename=prxchange('s/.*\s+([\S]+\.sas)/$1/',-1,filename);
 filename="&_MacroDir\"||filename;
 if prxmatch('/\.sas/',filename);
 run;
%end;
%else %do;
 filename M&di pipe "ls &_MacroDir";
 data tmp_&di;
 length filename $2000.;
 infile M&di lrecl=32767;
 input filename $;
 filename="&_MacroDir/"||filename;
 run;
%end;

%end;

data tmp;
set tmp_:;
*where filename contains '.sas';
if prxmatch("/&fileRgx/i",filename) and prxmatch("/\.sas/oi",filename) and 
   not prxmatch("/\.sas\.bak/i",filename) and not prxmatch("/importallmacros.*.sas/i",filename);
run;

%if &verbose=0 %then %do;
options notes;
%end;

/*proc print;run;*/
/*options mprint mlogic symbolgen;*/

data _null_;
set tmp;
%if &verbose=1 %then %do;
call execute('%put Now try to import the macro: '|| left(strip(filename)));
%end;
call execute('%include "' ||left(strip(filename))||'";');
%if &verbose=1 %then %do;
call execute('%put The import is OK for the macro: '|| left(strip(filename)));
%end;
run;

*title 'Loaded Macros into SAS';
/*proc print data=tmp;*
/*run;*/


%mend;

/*options mprint mlogic symbolgen;*/

/*

%importallmacros(MacroDir=E:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,fileRgx=Import,verbose=1);

*/
