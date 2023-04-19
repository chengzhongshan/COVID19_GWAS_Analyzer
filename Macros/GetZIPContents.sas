%macro GetZIPContents(zip,dsdout);
*this script is only able to get contents of ZIP but not gzip;
*as gzip can not be opened directly!;
%let rc=1;
filename inzip ZIP "&zip";
/* Read the "members" (files) from the ZIP file */
data &dsdout(keep=memname isFolder);
 length memname dirname $500 isFolder 8;
 fid=dopen("inzip");
 if fid=0 then do;
  memname="ERROR to read the zip file";
  call symput('rc',0);
  output;
  stop;
 end;
 memcount=dnum(fid);
 do i=1 to memcount;
  memname=dread(fid,i);
  /* check for trailing / in folder name */
  isFolder = (first(reverse(trim(memname)))='/');
  output;
 end;
 rc=dclose(fid);
run;

%if %eval(&rc=0) %then %do;
  %put Failed to read contents in the zip file:;
  %put The zip file is &zip;
  %abort 255;
%end;

*remove zip folder name from the zip contents dsd;
data &dsdout;
set &dsdout;
dirname=prxchange('s/^(.*)\/[^\/]+$/$1/',-1,memname);
memname=prxchange('s/^.*\/([^\/]+)$/$1/',-1,memname);
run;
 
/* create a report of the ZIP contents */
title "The first 10 files in the ZIP file: &zip";
proc print data=&dsdout(obs=10) noobs N;
run;
%mend;

/*Demo:
%let zipfile=xxx.zip;
%GetZIPContents(zip=&zipfile,dsdout=x);


*/

