%macro get_HGI_covid_gwas_from_grasp(gwas_url,outdsd);
%let wkdir=%sysfunc(getoption(work));
%let gwas_gz_file=%sysfunc(prxchange(s/.*\///,-1,&gwas_url));
%dwn_http_file(httpfile_url=&gwas_url,outfile=&gwas_gz_file,outdir=&wkdir);
*Uncompress the file in Windows;
%if &sysscp=WIN %then %do;
 %UncompressGZWith7ZInWindows(
gzfilepath=&wkdir/&gwas_gz_file,
globalvar4finalfile=finalfilepath 
);
%put Final uncompressed file fullpath is here:;
%put &finalfilepath;
*make the filename_rgx as empty, and the macro will treat the input as txt file;
%ImportHGICovidGWASFromZIP(zip=&finalfilepath,filename_rgx=,sasdsdout=&outdsd,deleteZIP=1);
%end;
%else %do;
/*Put tmp data into sas work directory will save space*/
/* %ImportTXTFromZIP(zip=&wkdir/&gwas_gz_file,filename_rgx=gz,sasdsdout=&outdsd, */
/* extra_proc_import_codes=%str(getnames=yes),deleteZIP=1); */
%ImportHGICovidGWASFromZIP(zip=&wkdir/&gwas_gz_file,filename_rgx=gz,sasdsdout=&outdsd,deleteZIP=1);
%end;

%if %rows_in_sas_dsd(test_dsd=&outdsd)=0 %then %do;
  %put There are no records in the GWAS dataset &outdsd;
  %put Please check the download link for the GWAS is correct:;
  %put &gwas_url;
  %abort 255;
%end;

/*print the first 10 records for the imported gwas*/
title "First 10 records in &outdsd derived from the gwas: &gwas_gz_file";
proc print data=&outdsd(obs=10);run;

%mend;

/*Demo:
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

%let gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B1_ALL_20201020.b37.txt.gz;
%get_HGI_covid_gwas_from_grasp(gwas_url=&gwas_url,outdsd=HGI_B1);

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.HGI_B1,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=%str("rs16831827"),
design_width=500,
design_height=300
);

%let gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz;
%get_HGI_covid_gwas_from_grasp(gwas_url=&gwas_url,outdsd=HGI_B2);

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.HGI_B2,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx2,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=%str("rs16831827"),
design_width=500,
design_height=300
);



/* Debugging only */
/* %let wkdir=%sysfunc(getoption(work)); */
/* %let gwas_gz_file=%sysfunc(prxchange(s/.*\///,-1,&gwas_url)); */
/* %dwn_http_file(httpfile_url=&gwas_url,outfile=&gwas_gz_file,outdir=&wkdir); */
/*  */
/* %let gzfile=&wkdir/COVID19_HGI_B1_ALL_20201020.b37.txt.gz; */
/* %ImportHGICovidGWASFromZIP(zip=&gzfile,filename_rgx=gz,sasdsdout=x,deleteZIP=0); */

