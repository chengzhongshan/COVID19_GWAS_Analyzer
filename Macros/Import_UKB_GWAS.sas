
%macro Import_UKB_GWAS(
ukb_file=both_sexes.INFLUENZA_All_influenza_not_pneumonia_,/*for gz file, need to provide fullpath*/
dsdout=x,
deleteZIP=0,
print_top_hits=0
);

/*data x;*/
/*infile 'both_sexes.INFLUENZA_All_influenza_not_pneumonia_' dsd lrecl=32767 dlm='09'x truncover firstobs=2 obs=max;*/
/**Need to provide '.' after data input format, otherwise, sas can not infile correctly;*/
/*input variant :$15.	minor_allele :$8.	minor_AF 	expected_case_minor_AC 	*/
/*low_confidence_variant :$5.	n_complete_samples 	AC 	ytx	 beta 	se 	tstat	pval ;*/
/*run;*/

*Need to provide '.' after data input format, otherwise, sas can not infile correctly;
%ImportFileHeadersFromZIP( 
zip=&ukb_file,
filename_rgx=., 
obs=max, 
sasdsdout=&dsdout, 
deleteZIP=&deleteZIP, 
infile_command=%str(dsd lrecl=32767 dlm='09'x truncover firstobs=2 obs=max;
input variant :$20.	minor_allele :$1.	minor_AF 	expected_case_minor_AC 	
low_confidence_variant :$5.	n_complete_samples 	AC 	ytx	 beta 	se 	tstat	pval ), 
use_zcat=0 
);

data &dsdout;
*To save space, all alleles were restricted to be length with 1;
length chr $2. allele $1 allele2 $1;
set &dsdout;
chr=scan(variant,1,':');
pos=scan(variant,2,':')+0;
allele1=scan(variant,3,':');
allele2=scan(variant,4,':');
run;

%let ukb_var_gz=https://broad-ukb-sumstats-us-east-1.s3.amazonaws.com/round2/annotations/variants.tsv.bgz;
%let wkdir=%sysfunc(getoption(work));
%dwn_http_file(httpfile_url=&ukb_var_gz,outfile=ukb_vars.gz,outdir=&wkdir);
*Get file headers;
%ImportFileHeadersFromZIP(
zip=&wkdir/ukb_vars.gz,
filename_rgx=.,
obs=max,
sasdsdout=rsids,
deleteZIP=1,
infile_command=%str(firstobs=2 obs=max dlm='09'x dsd truncover lrecl=32767;
input 	variant :$20. chr :$2. pos ref :$1. alt :$1. rsid :$20. 
varid :$20. consequence :$20. consequence_category :$10. info call_rate AC 
AF minor_allele :$1. minor_AF p_hwe n_called n_not_called 
n_hom_ref n_het n_hom_var n_non_ref r_heterozygosity 
r_het_hom_var :$2. r_expected_het_frequency;)
);

data rsids;set rsids(keep=chr pos rsid minor_allele);run;
*To save space, only keep specific variants and also exclude low MAF variants;
proc sql;
create table 
&dsdout(keep=chr pos SNP pval beta se minor_AF minor_allele low_confidence_variant allele1 allele2) 
as 
select a.*,b.rsid as SNP
from &dsdout(where=(minor_AF > 0.001)) as a
left join
rsids as b
on a.chr=b.chr and 
   a.pos=b.pos and
   a.minor_allele=b.minor_allele;
proc sql;
drop table rsids;
quit;

%chr_format_exchanger(
dsdin=&dsdout,
char2num=1,
chr_var=chr,
dsdout=&dsdout);

%if &print_top_hits=1 %then %do;
title "Top high confidence variants passed pval<1e-6 in the dataset &dsdout";
proc print data=&dsdout;
where pval<1e-6 and low_confidence_variant^="true";
run;
%end;

%mend;

/*Demo:

x cd J:\Coorperator_projects\Influenza_GWAS\UKB_Influenza_GWAS;
*%macroparas(macrorgx=fromzip);
options mprint mlogic symbolgen;
*For ukb gz file, need to provide fullpath;
%Import_UKB_GWAS(
ukb_file=J:\Coorperator_projects\Influenza_GWAS\UKB_Influenza_GWAS\both_sexes.INFLUENZA_All_influenza_not_pneumonia_.gz,
dsdout=x
);

*/
 

