%macro _is_sas_macro(file=, bytes=8192, mv=IS_SASMACRO);
    %if "%sysfunc(strip(&file))" ="" %then %do;
        %put ERROR: (is_sas_macro) FILE= must be specified.;
        %return;
    %end;
    %global &mv;
    %let _exists = %sysfunc(fileexist(%sysfunc(dequote(&file))));
    %if &_exists = 0 %then %do;
        %let &mv = 0;
        %put ERROR: (is_sas_macro) File &file does not exist.;
        %return;
    %end;

    %let _ext = %sysfunc(lowcase(%sysfunc(scan(%sysfunc(dequote(&file)),-1,.))));
    %if &_ext ^= sas %then %do;
        %let &mv = 0;
        %return;
    %end;

%*https://www.mwsug.org/proceedings/2017/BB/MWSUG-2017-BB142.pdf;
%*Note: using %sysfunc with bsubl enables the input commands without using quote;
%*In contrary, in data step, the using of bsubl is required to be with quoted strings;
%*the filename should be included in dosubl if the supplied commands include the filehandle;
%*It is very important to put these codes used by dosubl into the macro str but not nrbquote;
%*This is mainly because these codes should be geneated as string during compilation stage;
%let my_codes=%str(
filename _file "&file";
 data b;
        length line $32767;
		retain found 0;
        bytesread = 0;
        infile _file lrecl=32767 recfm=v length=reclen end=eof;
		do while(not eof and found=0 and bytesread < &bytes);
            input line $varying32767. reclen;
            bytesread + reclen;
            if index(lowcase(line),'%macro') > 0 then found = 1;
        end;
        call symputx("&mv",found,'G');
    run;
filename _file clear;	
 );
%*It is necessary to put the string into a variable for the function dosubl;
%*No line separations are allowed for codes supplied to the function dosubl;
%let y=%sysfunc(dosubl(&my_codes));
%*Note: this will output the value as a sas function;
&&&mv

%mend;

/*Demo codes:;
%debug_macro;
%let my_file_path = H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\is_sas_macro.sas; 
%let my_is_sasmacro=%_is_sas_macro(file=&my_file_path);
%put &IS_SASMACRO;
%put &my_is_sasmacro;

%let my_file_path =xxxx;
%_is_sas_macro(file=&my_file_path);
%put &IS_SASMACRO;
data a;
b=resolve('&IS_SASMACRO');
proc print;run;

*The following will fail if using dosubl but not resolve;
*due to the mask of global macro variable is_sasmacro by dosubl preventing it from accessing it outside;
%let my_file_path = H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\is_sas_macro.sas; 
data b;
*Do not use dosubl here;
y=resolve('%_is_sas_macro(file='||"&my_file_path"||')');
b=resolve('&IS_SASMACRO');
proc print;run;
%put &IS_SASMACRO;

*/


%macro _FileOrDirExist_(dir) ; 
   %LOCAL rc fileref return; 

   %*arbitrarily assign value 0 to output if dir is empty;
   %*This will avoid of error message issued by fexist later;
   %if %length(&dir)=0 %then %do;
          0
    %end;
	%*It is necessary to add else do macro statement here, otherwise, even if the above is true, later codes will still run by sas;
    %else %do;

   %let rc = %sysfunc(filename(fileref,&dir)) ; 
/*    %if &rc=0 and %sysfunc(fexist(&fileref))  %then %let return=1;     */
/*    %else %let return=0; */
/*    &return */
%*The above failed in SAS OnDemand but works in Windows;
%*The reason is because the sas funciton will return these sas comments if not escaped by %;
%*Note: it is necessary to assign &fileref but no filerefto fexist here!;
   %if %sysevalf(&rc=0 and %symexist(fileref) and %sysfunc(fexist(&fileref)))  %then %do;
       1
   %end;
   %else %do;
       0
   %end;
%end;

%mend;

%macro importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.sas,verbose=0);

%if not %_FileOrDirExist_(dir=&MacroDir)  %then %do;
 %put We are going to download the required SAS macros from github;
 	filename N url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/InstallGitHubZipPackage.sas";
  %include N;
  %InstallGitHubZipPackage( 
  git_zip=https://github.com/chengzhongshan/COVID19_GWAS_Analyzer/archive/refs/heads/main.zip, 
  homedir=%sysfunc(pathname(HOME)),/*SAS OnDemand for Academics HOME folder*/ 
  InstallFolder=Macros, /*Put all uncompressed files into the folder under the homedir*/ 
  DeletePreviousFolder=1, /*Delete previous InstallFolder if existing in the target homedir*/ 
  excluded_files_rgx=Differential_GWAS_between_UKB_Male_vs_Female_Hospitalization_GWAS|Evaluate_FOXP4_SNPs_with_both_long_COVID_and_severe_COVID|COVID19_GWAS_Analyzer_STAR_Protocol_Demo_Codes4MAP3K19|HGI_Hospitalization_GWAS_Analyzer|Differential_GWAS_between_HGI_B1_and_HGI_B2_ODA|PostGWAS4HGI_
  ); 
%end;
%else %do;
  %put The required SAS macros exist in the macro dir &MacroDir;
  %put We will not download these macros from github;
%end;


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
 if prxmatch('/\.sas/',filename) and scan(filename,-2,'/')='Macros' and length(scan(filename,-1,'/'))<36;
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
 where scan(filename,-2,'/')='Macros' and length(scan(filename,-1,'/'))<36;
 * delete sas files with length >32 + 4 (.sas), as these files are not sas macro;
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

*Only real macros will be kept;
data tmp(keep=filename);
set tmp;
ismacro=resolve('%_is_sas_macro(file='||filename||')');
if ismacro=1;
run;

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

filename loadmacros url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
%include loadmacros;;
%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0);

*/
