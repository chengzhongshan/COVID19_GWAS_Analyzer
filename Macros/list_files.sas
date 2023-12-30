%macro list_files(dir,file_rgx);
  %local filrf rc did memcnt name i;
  %let rc=%sysfunc(filename(filrf,&dir));
  %let did=%sysfunc(dopen(&filrf));      

   %if &did eq 0 %then %do; 
    %put Directory &dir cannot be open or does not exist;
    %return;
  %end;

  %do i = 1 %to %sysfunc(dnum(&did));   

   %let name=%qsysfunc(dread(&did,&i));

/*%if %qupcase(%qscan(&name,-1,.)) = %upcase(&file_rgx) %then %do;*/
   %if %sysfunc(prxmatch(/&file_rgx/i,&name)) %then %do;
        %put &dir/&name;
      %end;
      %else %if %qscan(&name,2,.) = %then %do;        
        %list_files(&dir/&name,&file_rgx)
      %end;

   %end;
   %let rc=%sysfunc(dclose(&did));
   %let rc=%sysfunc(filename(filrf));     

%mend list_files;

/*
options linesize=max;
proc printto log="list_files.txt" new;
run;
%list_files(E:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,sas);
proc printto;run;
proc printto log=log;
run;
%del_file_with_fullpath(fullpath=list_files.txt);

*/
