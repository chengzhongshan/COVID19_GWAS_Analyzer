
%macro cp_files_in_dsd(dsd,filevar,indir,outdir,newfiletag);
 proc sql noprint;
 select count(&filevar) into: n
 from &dsd;
 proc sql noprint;
 select unique(&filevar) into:v1-:v%sysfunc(left(&n))
 from &dsd;
 %if (&newfiletag ne and &indir eq &outdir) %then %do;
  %do i=1 %to &n;
    %cp(f=&&v&i,fdir=&indir,
    out=&newfiletag..&&v&i,outdir=&outdir);
  %end;
  %end;
  %else %do;
    %do i=1 %to &n;
     %cp(f=&&v&i,fdir=&indir,
     out=&&v&i,outdir=&outdir);
	%end;
  %end;

%mend;


/*

%get_filenames(location=%bquote(D:\TCGA_LargeDB\CESC\cds_sorted),dsd_out=filenames);
data filenames;
set filenames;
file=memname;
substr(memname,13,8)="";
memname=strip(left(memname));
run;
proc sort data=filenames nodupkeys;by _all_;run;
data a;
length memname $12.;
input memname $;
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

options mprint mlogic symbolgen;
%cp_files_in_dsd(dsd=left_ids,
                 filevar=file,
                 indir=D:\TCGA_LargeDB\CESC\cds_sorted,
                 outdir=D:\TCGA_LargeDB\CESC\cds_sorted,
                 newfiletag=xxx);
*/
