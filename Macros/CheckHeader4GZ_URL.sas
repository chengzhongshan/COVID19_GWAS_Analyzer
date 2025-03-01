%macro CheckHeader4GZ_URL(
any_gz_url=,
infile_cmd=%str(firstobs=1 obs=max;input;info=_infile_;),
/*Provide command like the following using the macro str to wrap it;
Note: ensure there is not infile put before any supplied infile_cmd, as the infile 
statement is hard-coded into the internal macro!
*/
outdsd=
);
%let OldOutDsd=&Outdsd;
*If the outdsd contains lib abbreviation;
*It is necessary to generate a gbff dsd in working directory first.;
%if %index(&OldOutDsd,.) %then %do;
 %let outdsd=%scan(&outdsd,2,.);
%end;

%let wkdir=%sysfunc(getoption(work));
%let gbff_gz_file=%sysfunc(prxchange(s/.*\///,-1,&any_gz_url));
%dwn_http_file(httpfile_url=&any_gz_url,outfile=&gbff_gz_file,outdir=&wkdir);
/*Put tmp data into sas work directory will save space*/
/* %ImportTXTFromZIP(zip=&wkdir/&gbff_gz_file,filename_rgx=gz,sasdsdout=&outdsd, */
/* extra_proc_import_codes=%str(getnames=yes),deleteZIP=1); */

*Note: the following codes just read the raw gbff file as a single variable;
%symdel obs;

%ImportFileHeadersFromZIP(
zip=&wkdir/&gbff_gz_file,
filename_rgx=gz,
obs=max,
sasdsdout=&outdsd,
deleteZIP=0,
infile_command=&infile_cmd
);

/*print the first 10 records for the imported gwas*/
title "First 10 records in &outdsd derived from the gbff: &gbff_gz_file";
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

%let any_gz_url=https://ftp.ncbi.nlm.nih.gov/genomes/refseq/vertebrate_mammalian/Homo_sapiens/annotation_releases/current/GCF_000001405.40-RS_2024_08/GCF_000001405.40_GRCh38.p14_genomic.gbff.gz;;
*%debug_macro;

%CheckHeader4GZ_URL(any_gz_url=&any_gz_url,outdsd=gbff_hg38);

proc datasets nolist;
copy in=work out=FM memtype=data move;
select gbff_hg19;
run;

*/
