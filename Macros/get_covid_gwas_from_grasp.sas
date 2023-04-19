%macro get_covid_gwas_from_grasp(gwas_url,outdsd);
%let wkdir=%sysfunc(getoption(work));
%let gwas_gz_file=%sysfunc(prxchange(s/.*\///,-1,&gwas_url));
%dwn_http_file(httpfile_url=&gwas_url,outfile=&gwas_gz_file,outdir=&wkdir);
/*Put tmp data into sas work directory will save space*/
/* %ImportTXTFromZIP(zip=&wkdir/&gwas_gz_file,filename_rgx=gz,sasdsdout=&outdsd, */
/* extra_proc_import_codes=%str(getnames=yes),deleteZIP=1); */
%ImportCovidGWASFromZIP(zip=&wkdir/&gwas_gz_file,filename_rgx=gz,sasdsdout=&outdsd,deleteZIP=1);
/*print the first 10 records for the imported gwas*/
title "First 10 records in &outdsd derived from the gwas: &gwas_gz_file";
proc print data=&outdsd(obs=10);run;

%mend;

/*Demo:
%let gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_AFR_061821.txt.gz;
%get_covid_gwas_from_grasp(gwas_url=gwas.gz,outdsd=ukb_afr);

*/
