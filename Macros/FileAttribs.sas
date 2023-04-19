%macro FileAttribs(filename);           
  %local rc fid fidc Bytes CreateDT ModifyDT; 
  %let rc=%sysfunc(filename(onefile,&filename)); 
  %let fid=%sysfunc(fopen(&onefile));
     %if &fid ne 0 %then %do;  
  %let Bytes=%sysfunc(finfo(&fid,File Size (bytes)));   
  %let CreateDT=%sysfunc(finfo(&fid,Create Time));     
  %let ModifyDT=%sysfunc(finfo(&fid,Last Modified));    
  %let fidc=%sysfunc(fclose(&fid));    
  %let rc=%sysfunc(filename(onefile)); 
  %put NOTE: File size of &filename is &bytes bytes (%sysevalf(&bytes/(1024*1024),integer) Mb);    
  %put NOTE- Created &createdt;       
  %put NOTE- Last modified &modifydt;
  %put the size of the file in Mb is retured by the maro;
  %sysevalf(&bytes/(1024*1024),integer)
     %end;
        %else %put &filename could not be open.;
%mend FileAttribs;
/* 
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;  
                   
%let size=%FileAttribs(/home/cheng.zhong.shan/data/GTEx_V8/all.sas7bdat);
%put &size Mb;


*/
