%macro get_HGI_covid_gwas_from_HGI(
gwas_url,
outdsd,
for_subpop=0 /*R7 GWAS for ALL and sub-populations are in different format*/
);
%let wkdir=%sysfunc(getoption(work));
%let gwas_gz_file=%sysfunc(prxchange(s/.*\///,-1,&gwas_url));
%dwn_http_file(httpfile_url=&gwas_url,outfile=&gwas_gz_file,outdir=&wkdir);
/*Put tmp data into sas work directory will save space*/
/* %ImportTXTFromZIP(zip=&wkdir/&gwas_gz_file,filename_rgx=gz,sasdsdout=&outdsd, */
/* extra_proc_import_codes=%str(getnames=yes),deleteZIP=1); */
%ImportHGICovidGWASFromHGI_R7(
zip=&wkdir/&gwas_gz_file,
filename_rgx=gz,
sasdsdout=&outdsd,
deleteZIP=1,
for_subpop=&for_subpop
);
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
 
%let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_afr_leave23andme_20220403_GRCh37.tsv.gz;

*/

*get headers of gz file;
*for debugging;
/* *Get HGI release GWAS gz file header; */
/* %let wkdir=%sysfunc(getoption(work)); */
/* %dwn_http_file(httpfile_url=&gwas_url,outfile=gwas_gz_file.gz,outdir=&wkdir); */
/* %ImportFileHeadersFromZIP( */
/* zip=&wkdir/gwas_gz_file.gz,/*Only provide file with .gz, .zip, or common text file without comporession */
/* filename_rgx=., */
/* obs=max, */
/* sasdsdout=x, */
/* deleteZIP=0, */
/* infile_command=%str(firstobs=1 obs=10;input;info=_infile_;), */
/* use_zcat=0 */
/* ); */
/* proc print data=_last_(obs=1);run; */
/* CHR POS REF ALT SNP  */
/* all_meta_N all_inv_var_meta_beta  */
/* all_inv_var_meta_sebeta all_inv_var_meta_p  */
/* all_inv_var_meta_cases all_inv_var_meta_controls  */
/* all_inv_var_meta_effective all_inv_var_het_p  */
/* all_meta_AF rsid b38_chr b38_pos b38_ref b38_alt liftover_info; */

/*Demo continued:

options mprint mlogic symbolgen;

%get_HGI_covid_gwas_from_HGI(gwas_url=&gwas_url,outdsd=HGI_B1_afr);
proc print data=HGI_B1_afr;where p<1e-7;run;
 
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.HGI_B1_afr,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx,
gwas_thrsd=5,
Mb_SNPs_Nearby=1,
snps=%str(rs184840644 rs4646138),
design_width=500,
design_height=300
);

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

%Gene_Local_Manhattan_With_GTF(
gwas_dsd=HGI_B1_afr,
gwas_chr_var=chr,
gwas_AssocPVars=p,
Gene_IDs=MAP3K19,
dist2Gene=500000,
SNP_Var_GWAS=rsid,
Pos_Var_GWAS=pos,
gtf_dsd=FM.GTF_HG19,
Gene_Var_GTF=Genesymbol,
GTF_ST_Var=st,
GTF_End_Var=end,
ZscoreVars=beta,
design_width=800, 
design_height=600, 
barthickness=15, 
dotsize=8, 
dist2sep_genes=1000,
where_cndtn_for_gwasdsd=%str(p<1)
);
 
 

*/
