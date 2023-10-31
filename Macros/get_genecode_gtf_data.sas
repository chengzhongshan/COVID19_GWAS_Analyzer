%macro get_genecode_gtf_data(gtf_gz_url,outdsd);
%let OldOutDsd=&Outdsd;
*If the outdsd contains lib abbreviation;
*It is necessary to generate a gtf dsd in working directory first.;
%if %index(&OldOutDsd,.) %then %do;
 %let outdsd=%scan(&outdsd,2,.);
%end;

%let wkdir=%sysfunc(getoption(work));
%let gtf_gz_file=%sysfunc(prxchange(s/.*\///,-1,&gtf_gz_url));
%dwn_http_file(httpfile_url=&gtf_gz_url,outfile=&gtf_gz_file,outdir=&wkdir);
/*Put tmp data into sas work directory will save space*/
/* %ImportTXTFromZIP(zip=&wkdir/&gtf_gz_file,filename_rgx=gz,sasdsdout=&outdsd, */
/* extra_proc_import_codes=%str(getnames=yes),deleteZIP=1); */
%ImportGendcodeGTFFromZIP(zip=&wkdir/&gtf_gz_file,filename_rgx=gz,sasdsdout=&outdsd,deleteZIP=1);
/*print the first 10 records for the imported gwas*/
title "First 10 records in &outdsd derived from the gtf: &gtf_gz_file";
proc print data=&outdsd(obs=10);run;

%if %index(&OldOutDsd,.) %then %do;
proc datasets nolist;
copy in=work out=%scan(&OldOutDsd,1,.) memtype=data move;
select &outdsd;
run;
%end;

%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

%let gtf_gz_url=https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz;
%get_genecode_gtf_data(gtf_gz_url=&gtf_gz_url,outdsd=gtf_hg19);

proc datasets nolist;
copy in=work out=FM memtype=data move;
select gtf_hg19;
run;

*/
