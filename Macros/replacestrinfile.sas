%macro replacestrinfile(file,strrgx,newstr4rep,casesensitive=0,outdir=,outprefix=modified.,firstobs=1,obs=max);
   filename IN "&file";
   
   %if "&outdir"="" %then %do;
   %let outdir=%curdir;
/*   %let outdir=%sysfunc(getoption(work));*/
   %end;

   filename OUT "&outdir/&outprefix.&file";
   data _null_;
   infile IN lrecl=32767 firstobs=&firstobs obs=&obs;
   file OUT lrecl=32767;
   input;
   %if &casesensitive %then %do;
     _infile_=prxchange("s/&strrgx/&newstr4rep/",-1,_infile_);
   %end;
   %else %do;
     _infile_=prxchange("s/&strrgx/&newstr4rep/i",-1,_infile_);
   %end;
   put _infile_;
   run;
%mend;

/*Demo:
x cd J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS\UKB_Covid19_GWAS;

options mprint mlogic symbolgen;
*Can not use '\t', need to use '	' for strrgx and newstr4rep;

%replacestrinfile(
file=UKBB_covid19_ALL_F_080420.txt,
strrgx=X	,
newstr4rep=23	,
casesensitive=0,
outdir=,
firstobs=1,
obs=10
);
*/

