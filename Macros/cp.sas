%macro cp(f,fdir,out,outdir);
%let filrf=myfile;
%let rc=%sysfunc(filename(filrf, &fdir\&f));
%let cpfileref=myfilecp;
%let rc1=%sysfunc(filename(cpfileref,&outdir\&out));
%let fid=%sysfunc(fcopy(&filrf,&cpfileref));
%put &fid;

%if &fid=0 %then %do;
 %put "copy it successfully for" &fdir\&f ", which is saved into " &outdir\&out;
%end;
%else %do;
 %put &fdir\&f "doesn't exist";
 %abort 255;
%end;

%mend;
/*
options mprint mlogic symbolgen;
%cp(f=z.bed,fdir=D:\TCGA_LargeDB\CESC\cds_sorted,
    out=y.bed,outdir=D:\TCGA_LargeDB\CESC\cds_sorted);
*/

/*%get_filenames(location=%bquote(D:\TCGA_LargeDB\CESC\cds_sorted),dsd_out=filenames);
data filenames;
set filenames;
file=memname;
substr(memname,13,8)="";
memname=strip(left(memname));
run;
proc sort data=filenames nodupkeys;by _all_;run;
data a;
input memname $1000.;
cards;
TCGA-EX-A1H5
TCGA-EA-A1QS
TCGA-C5-A2LX
TCGA-EK-A2RL
TCGA-FU-A3HY
TCGA-EA-A3HT
TCGA-C5-A3HD
TCGA-C5-A2LV
;
run;
proc sql;
create table left_ids as
select *
from filenames as a,a as b
where a.memname=b.memname;

data _null_;
set left_ids;
call execute(
'%cp(f='||strip(left(file))||
',fdir='||'D:\TCGA_LargeDB\CESC\cds_sorted'||
',out='||strip(left(file))||'.new.bed, outdir=D:\TCGA_LargeDB\CESC\cds_sorted)');
run;
*/
