%macro dwn_http_file(httpfile_url,outfile,outdir);
%if "&outfile"="" %then %do;
%let outfile=%sysfunc(prxchange(s/.*\///,-1,&httpfile_url));
%end;
%if "&outdir"="" %then %do;
*%let outdir=%curdir;
%let outdir=%sysfunc(getoption(work));
%end;
%put Downloaded file will be put into here:;
%put &outdir/&outfile;
filename out "&outdir/&outfile";
proc http
 url="&httpfile_url"
 method="get" out=out;
run;
%mend;

/*Demo:
%let httpfile_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_AFR_061821.txt.gz;
%dwn_http_file(httpfile_url=&httpfile_url,outfile=,outdir=/home/cheng.zhong.shan);
*In SAS ondemand, putting data into the temporary work directory will not be limited by the 5GB quota!;
%dwn_http_file(httpfile_url=&httpfile_url,outfile=,outdir=%sysfunc(getoption(work)));
*/

