%macro Zip4Windows(Dir_or_files,out7z);
options nonotes;
data _null_;
/*  infile 'c:\progra~1\"Easy 7-zip"\7z.exe a -r &out7z.7z F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\*' pipe ;*/
/*use dir /x to get fullname of Easy 7-zip under the dir c:\progra~1*/
  infile "c:\progra~1\Easy7-~1\7z.exe a -r &out7z..7z &Dir_or_files" pipe ;
input ;
put _infile_;
run;
options note;
%mend;



/*Provide path for dir or file, no 7z appendix for out7z*/
/*

%let Dir=F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\*;
%Zip4Windows(Dir_or_files=&Dir,out7z=H:\SASMacros);

*/

