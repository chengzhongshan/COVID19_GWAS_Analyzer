*Note: file_rgx is char insensitive for prxmatch;
%macro list_files2globalvar(dir,file_rgx,filelistvar);
  %global &filelistvar;
  %let &filelistvar=;
  /*reset the value of the global macro var*/
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
        /*get fullpath, but the global var would be too long*/
        /*%let &filelistvar=&&&filelistvar "&dir/&name"; */
        /*get relative pathes and separate them by ':'*/
        %if %index(&name,%str( )) %then %do;
         %put The file "&name" contain space, which will be omitted!;
        %end;
        %else %do;
         /*replace the starting char :*/
         %let &filelistvar=%sysfunc(prxchange(s/^://,-1,&&&filelistvar.:&name));
        %end;
      %end;
      /*if not '.' in file name, it will be treated as a folder*/
      /*which may be a potential bug when some files don't have .*/
      /*%else %if %qscan(&name,2,.) = %then %do;*/
        %else %if %isDir(iPath=&name) %then %do;        
        %list_files(&dir/&name,&file_rgx)
      %end;

   %end;
   %let rc=%sysfunc(dclose(&did));
   %let rc=%sysfunc(filename(filrf));     

%mend;

/*Demo:
  options mprint mlogic symbolgen;
  %list_files2globalvar(dir=/home/cheng.zhong.shan/Macros,
  file_rgx=sas,filelistvar=allsasmacrofiles);
  %put &allsasmacrofiles;
  
*/

