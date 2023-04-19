
%macro importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.sas,verbose=0);
%put Macro Dir is &MacroDir;
%put Your system is &sysscp;

%let ndirs=%sysfunc(countc(&MacroDir,' '))+1;

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

*UE can not use pipe;
/*
 filename M&di pipe "ls &_MacroDir";
 data tmp_&di;
 length filename $2000.;
 infile M&di lrecl=32767;
 input filename $;
 filename="&_MacroDir/"||filename;
 run;
 */
*It is necessary to include list_files.sas for successfully running of listfiles2dsdInUE.sas;
*%include "&macrodir/list_files.sas";
%include "&Macrodir/listfiles2dsdInUE.sas";
 *The follow macro will create table tmp_&di that contains the var filename;
 %listfiles2dsdInUE(&MacroDir,sas\s*$,tmp_&di);
 data tmp_&di;
 set tmp_&di;
 where scan(filename,-2,'/')='Macros';
 run;
/*  proc print;run; */
 /*%abort 255;*/
%end;

%end;

data tmp;
set tmp_:;
*where filename contains '.sas';
if prxmatch("/&fileRgx/i",filename) and prxmatch("/\.sas/oi",filename) and 
   not prxmatch("/\.sas\.bak/i",filename) and not prxmatch("/importallmacros/i",filename);
run;

/*proc print;run;*/
/*options mprint mlogic symbolgen;*/

data _null_;
set tmp;
%if &verbose=1 %then %do;
call execute('%put Now try to import the macro: '|| left(strip(filename)));
%end;
call execute('%include "' ||left(strip(filename))||'" / lrecl=5000;');
if _error_ then do;
put filename;
end;
%if &verbose=1 %then %do;
call execute('%put The import is OK for the macro: '|| left(strip(filename)));
%end;
run;

/*title 'Loaded Macros into SAS';*/
/*proc print data=tmp;*/
/*run;*/


%mend;

/*options mprint mlogic symbolgen;*/

/*

%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=Import,verbose=1);

*/
