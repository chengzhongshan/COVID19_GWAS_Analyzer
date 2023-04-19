*options mprint macrogen mlogic symbolgen;
*See SAS PDF SAS Macro to back up files across Multiple Directories.pdf for more details.;
%macro copyfiles(num); 
 proc sql noprint; 
 select filename into: name 
 from filenames 
 where ord=&num; 
 quit; 
 
 options noxwait; 
 %local rc fileref ; 
 %let rc = %sysfunc(filename(fileref,%qcmpres(&inpath\&moddate))) ; 
 %if %sysfunc(fexist(&fileref)) %then %do; 
 %sysexec copy "%qcmpres(&inpath\&name)" 
 "%qcmpres(&outpath\%qcmpres(&moddate)\&name)" ; 
 %end; 
 %else %do ; 
 %let rc = %sysfunc(filename(fileref,%qcmpres(&inpath\&moddate))) ; 
 %sysexec copy "%qcmpres(&inpath\&name)" 
 "%qcmpres(&outpath\%qcmpres(&moddate)\&name)" ; 
 %end ; 
 %let rc=%sysfunc(filename(fileref)) ; 
%mend; 

%macro gocopy; 
 %do i=1 %to &maxord; 
 %copyfiles(&i); 
 %end; 
%mend;

%macro dircopy(inpath,outpath); 
%let fref=%unquote(%str(%')dir /Q %str(%")&inpath.\*.* %str(%")%str(%')); 
filename allfil pipe &fref; 
data test(keep=mydate); 
 length v1 v2 v3 v4 owner filnam $100; 
 infile allfil truncover end=eof; 
 input v1 v2 v3 v4 owner filnam; 
 MYDATE = trim(left(scan(v1,3,'/')))|| 
 trim(left(scan(v1,1,'/')))||trim(left(scan(v1,2,'/'))); 
 if index(v1,'/') and v4^='<DIR>'; /*** v4 indicates if it is a subdirectory ***/ 
run;
 
proc sql noprint; 
 select max(mydate) into: moddate from test;

options noxwait; 
 %local rc fileref ; 
 %let rc = %sysfunc(filename(fileref,%qcmpres(&inpath\&moddate))) ; 
 %if %sysfunc(fexist(&fileref)) %then 
 %sysexec md "%qcmpres(&outpath\&moddate.)" ; 
 %else %do ; 
 %sysexec md "%qcmpres(&outpath\&moddate)" ; 
 %end ; 
 %let rc=%sysfunc(filename(fileref)) ;


%let indir=&inpath; 
%let nfiles=0; 
filename indir "&indir"; 
 
data _filenames1(where=(index(filename,'.'))); 
 format filename $250. ; 
 did=dopen('indir'); 
 do i=1 to dnum(did); 
 filename=dread(did,i); 
 output; 
 end; 
 rc=dclose(did); 
 keep filename ; 
run; 
 
data filenames; 
 set _filenames1; 
 ord=_n_; 
run; 
 
proc sql noprint; 
 select max(ord) into: maxord 
 from filenames; 
quit;

%gocopy;

%mend;


/*
%dircopy(inpath=I:\SASGWASDatabase\cis-eQTL_LD_Data,outpath=I:\SASGWASDatabase);
*/
