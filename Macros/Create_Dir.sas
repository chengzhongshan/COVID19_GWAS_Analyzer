/*An alternative way to create new directory;
%macro Create_Dir(dir=) ; 
   options noxwait; 
   %local rc fileref ; 
   %let rc = %sysfunc(filename(fileref,&dir)) ; 
   %if %sysfunc(fexist(&fileref))  %then 
      %put NOTE: The directory "&dir" exists ; 
   %else 
     %do ; 
         %sysexec md   &dir ; 
         %put %sysfunc(sysmsg()) The directory has been created. ; 
   %end ; 
   %let rc=%sysfunc(filename(fileref)) ; 
%mend Create_Dir ; 

%Create_Dir(dir=c:\temp) ;    %*   <==  your directory specification goes here ; 
%Create_Dir(dir=c:\temp\sascode);   
*/

%macro Create_Dir(path,folder_name);
%local rc fileref;
%let rc=%sysfunc(filename(fileref,&path/&folder_name));
%if %sysfunc(fexist(&fileref)) %then
   %put NOTE: The directory "&path/&folder_name" exists;
%else %do;
  data _null_;
  newDirectory=dcreate("&folder_name","&path");*dcreate(Dir_name,Path);
  run;
%end;
%mend;

/*
options mprint symbolgen mlogic;
%Create_Dir(
           path=I:\SASGWASDatabase\Important_Analysis_Codes\IndelLDplot_SAS,
           folder_name=PLINK
);
*/
