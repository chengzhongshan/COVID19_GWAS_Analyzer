%macro FileOrDirExist(dir) ; 
   %LOCAL rc fileref return; 
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
%mend;

/*
options mprint mlogic symbolgen;
%let  ext=%FileOrDirExist(H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros\FileOrDirExist.sas);
%put &ext;
*/
