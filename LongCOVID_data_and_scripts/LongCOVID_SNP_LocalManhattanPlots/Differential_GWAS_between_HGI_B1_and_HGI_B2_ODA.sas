*https://sesug.org/proceedings/sesug_2024_SAAG/PresentationSummaries/Papers/151_Final_PDF.pdf;
*options mprint mlogic symbolgen;
filename M url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
%include M;
Filename M clear;
%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0);
/* %macroparas(macrorgx=HGI); */


%let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/main/sumstats/COVID19_HGI_B1_ALL_leave_23andme_20220403_GRCh37.tsv.gz;
%get_HGI_covid_gwas_from_HGI(gwas_url=&gwas_url, outdsd=HGI_B1, for_subpop=0);
/* data HGI_B1(drop=het_p AF); */
data HGI_B1;
	set HGI_B1;
	if rsid="" then
		rsid=catx(':', chr, pos);
run;

%let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/main/sumstats/COVID19_HGI_B2_ALL_leave_23andme_20220403_GRCh37.tsv.gz;
%get_HGI_covid_gwas_from_HGI(gwas_url=&gwas_url, outdsd=HGI_B2, for_subpop=0);
data HGI_B2(drop=het_p AF);
	set HGI_B2;
	if rsid="" then
		rsid=catx(':', chr, pos);
run;

%DiffTwoGWAS(gwas1dsd=HGI_B1, gwas2dsd=HGI_B2, gwas1chr_var=chr, 
	gwas1pos_var=pos, snp_varname=rsid, beta_varname=beta, se_varname=se, 
	p_varname=P, gwasout=HGI_B1_vs_B2, stdize_zscore=1, allele1var=ref, 
	allele2var=alt, mk_manhattan_qqplots4twoGWASs=0);
*To reduce the size of the two datasets, only keep necessary columns;
data HGI_B1;
set HGI_B1;
keep rsid beta se p;
data HGI_B2;
set HGI_B2;
keep rsid beta se p;
run;
*Save these GWAS datasets into a library for later reuse;

proc datasets nolist;
	copy in=work out=D memtype=data move;
	*Keeping all GWAS datasets may result in out of disk space in SAS onDemand for Academics;
/* 	select HGI_B:; */
	select HGI_B1_vs_B2;
run;

proc sql;
select count(*) from D.HGI_B1_vs_B2;

*Evaluate these top SNPs in COVID19 susceptibility GWAS;
%let covid_suscept_gwas=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/main/sumstats/COVID19_HGI_C2_ALL_leave_23andme_20220403_GRCh37.tsv.gz;
%get_HGI_covid_gwas_from_HGI(gwas_url=&covid_suscept_gwas, outdsd=HGI_C2,for_subpop=0);
data HGI_C2;
	set HGI_C2;
	if rsid="" then
		rsid=catx(':', chr, pos);
run;

proc print data=D.HGI_B1_vs_B2(obs=10);
run;
proc print data=HGI_C2(obs=10);
run;

proc sql;
	create table ThreeGWAS as select a.rsid, a.chr, a.pos,a.ref,a.alt,
	    a.gwas1_beta as HGI_B1_beta, a.gwas2_beta as HGI_B2_beta, 
	    a.gwas1_P as HGI_B1_P, a.gwas2_P as HGI_B2_P,  
	    a.gwas1_se as HGI_B1_se, a.gwas2_se as HGI_B2_se, a.pval as diff_P, 
		a.diff_zscore, b.p as HGI_C2_P, b.beta as HGI_C2_beta, b.se as HGI_C2_se,
		b.AF as HGI_C2_AF
		from 
		D.HGI_b1_vs_b2 as a left join HGI_C2 as b on a.rsid=b.rsid and a.chr=b.chr 
		and a.pos=b.pos and a.ref=b.ref and a.alt=b.alt
		order by a.chr,a.pos;
%ds2csv(data=ThreeGWAS,csvfile=%sysfunc(pathname(HOME))/ThreeGWASs.csv,runmode=b);
