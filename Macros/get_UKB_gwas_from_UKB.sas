%macro get_UKB_gwas_from_UKB(gwas_url,outdsd);
%let wkdir=%sysfunc(getoption(work));
%let gwas_gz_file=%sysfunc(prxchange(s/.*\///,-1,&gwas_url));
%dwn_http_file(httpfile_url=&gwas_url,outfile=&gwas_gz_file,outdir=&wkdir);
/*Put tmp data into sas work directory will save space*/
/* %ImportTXTFromZIP(zip=&wkdir/&gwas_gz_file,filename_rgx=gz,sasdsdout=&outdsd, */
/* extra_proc_import_codes=%str(getnames=yes),deleteZIP=1); */
%Import_UKB_GWAS(
ukb_file=&wkdir/&gwas_gz_file,
dsdout=&outdsd,
deleteZIP=1,
print_top_hits=0
);
/*print the first 10 records for the imported gwas*/
title "First 10 records in &outdsd derived from the gwas: &gwas_gz_file";
proc print data=&outdsd(obs=10);run;
title "";

%mend;

/*Demo:
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

*%let gwas_url=https://broad-ukb-sumstats-us-east-1.s3.amazonaws.com/round2/additive-tsvs/INFLUENZA.gwas.imputed_v3.both_sexes.tsv.bgz;
*%get_UKB_gwas_from_UKB(gwas_url=&gwas_url,outdsd=UKB_GWAS);

*data UKB_GWAS;
*set UKB_GWAS;
*where minor_AF>0.01 and low_confidence_variant='false';
*run;

*proc datasets;
*copy in=work out=FM memtype=data move;
*select UKB_GWAS;
*run;

data top;set FM.UKB_GWAS;where pval<1e-6;run;
proc print data=FM.UKB_GWAS;where snp="rs2070788";run;

*Evaluate specific SNP;
data x;
set FM.UKB_GWAS;
logP=-log10(pval);
where chr=8 and pos between 38348509 and 39006758 and pval<0.05;
run;

*Top SNP is rs370604612;
proc sql;
select chr,snp,pos-1000000,pos+1000000 into: chr,:topsnp,:minst,:maxend
from x
having pval=min(pval);

%map_grp_assoc2gene4covidsexgwas( 
gwas_dsd=FM.UKB_GWAS, 
gtf_dsd=FM.GTF_HG19, 
chr=&chr, 
min_st=&minst, 
max_end=&maxend, 
dist2genes=1000, 
AssocPVars=pval, 
ZscoreVars=beta, 
design_width=800, 
design_height=600, 
barthickness=15, 
dotsize=8, 
dist2sep_genes=1000,
where_cndtn_for_gwasdsd=%str(pval<1)
); 


%debug_macro;
*The following macro will fail if no top SNPs pass the log10P < gwas_thrsd threshold;
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=FM.UKB_GWAS,
Marker_Col_Name=SNP,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=pval,
GWAS_dsdout=indep_top,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=10,
snps=%str(rs74823374),
design_width=500,
design_height=300
);
quit;

**These codes works;
*If the pos_dis_thrhd or signal_thrshdis too large, SAS OnDemand may be out of space;
%get_top_signal_within_dist(
dsdin=FM.UKB_GWAS
,grp_var=chr
,signal_var=pval
,select_smallest_signal=1
,pos_var=pos
,pos_dist_thrshd=10000000
,dsdout=topsnps
,signal_thrshd=1e-5);

proc sql noprint;
select SNP into: top_snps separated by ' '
from topsnps;

*Due to the use of internal macro local_multigwas_manhattan;
*only snps passed the p < 1e-6 will be plotted;
%local_multigwas_manhattan(
GWAS_SAS_DSD=FM.ukb_gwas,
Marker_Col_Name=snp,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Names=pval,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=&top_snps,
design_width=1600,
design_height=300,
Labels4gwas_grps=UKB_GWAS
);
quit;

proc sql noprint;
select pos-500000, pos+500000, chr into: minst, :maxend, :chr
       from UKB_GWAS
       where snp="rs2070788";
ods graphics on /reset=all;
libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
%map_grp_assoc2gene4covidsexgwas(
gwas_dsd=UKB_GWAS,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
dist2genes=0,
AssocPVars=pval ,
ZscoreVars=beta ,
design_width=800,
design_height=400,
barthickness=8,
dotsize=6,
dist2sep_genes=10000 
);


*****************************************************************************************************;
%let gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz;
%get_UKB_gwas_from_UKB(gwas_url=&gwas_url,outdsd=HGI_B2);

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.HGI_B2,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx2,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=%str(rs16831827),
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


*/
