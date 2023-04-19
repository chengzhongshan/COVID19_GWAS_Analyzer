%macro UKB_Female_vs_Male_GWAS_Pipeline(
female_gwas_url,
male_gwas_url,
female_male_gwas_url,
outdir=/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp,
forece=1,
label4female_gwas=Female,/*this label will be used to name the first GWAS in the figure and output*/
label4male_gwas=Male,/*this label will be used to name the second GWAS in the figure and output*/
label4f_vs_m=Female_vs_Male, /*this label will be used to name diff_GWAS for the 1st and 2nd GWASs in the figure and output*/
draw_p_axis_by_z_direction=1, /*Draw the log10P value axis on the end-right by +/- direction of its corresponding z-scores*/
From_GRASP_DB=1 /*point out the GWAS urls are from GRASP database; otherwise, it would be from UKB GWAS from Neale lab: http://www.nealelab.is/uk-biobank*/
);
*Use EUR COVID19 GWAS;
/* %let GWAS_F_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_EUR_F_061821.txt.gz; */
/* %let GWAS_M_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_EUR_M_061821.txt.gz; */
/* %let GWAS_FM_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_EUR_061821.txt.gz; */

%let GWAS_F_url=&female_gwas_url;
%let GWAS_M_url=&male_gwas_url;
%let GWAS_FM_url=&female_male_gwas_url;
libname FM "&outdir";

%if %sysfunc(exist(FM.F_vs_M_gwas)) and %eval(&forece^=1) %then %do;

   %put Previous GWAS results V_vs_M_gwas exists in your target dir &outdir;
   %put We will not generate the gwas dataset again but use it directly;

%end;

%else %do;

   %if &From_GRASP_DB=1 %then %do;
   *Better to use EUR samples, as only ~500 samples out of 3260 sam-ples are from other ancestries;
   *This will lead to more reliable results without of potential effect from opulation effect!;

   %get_covid_gwas_from_grasp(gwas_url=&GWAS_F_url,outdsd=ukb_F_gwas);
   %get_covid_gwas_from_grasp(gwas_url=&GWAS_M_url,outdsd=ukb_M_gwas);
   %get_covid_gwas_from_grasp(gwas_url=&GWAS_FM_url,outdsd=ukb_FM_gwas);

   *For debugging;
   /* %let gzfile=/saswork/SAS_workEEF600002F6E_odaws03-usw2.oda.sas.com/SAS_work7C0400002F6E_odaws03-usw2.oda.sas.com/UKBB_hsptl_EUR_F_061821.txt.gz; */
   /* %ImportFileHeadersFromZIP(zip=&gzfile,filename_rgx=gz,obs=max,sasdsdout=x,deleteZIP=0 */
   /* infile_command=%str(firstobs=1 obs=10;input;info=_infile_;)); */

   proc print data=ukb_F_gwas(obs=1);run;
   data ukb_F_gwas;set ukb_F_gwas;keep chr rsid p SE BETA pos allele1 allele2;
   proc print data=ukb_M_gwas(obs=1);run;
   data ukb_M_gwas;set ukb_M_gwas;keep chr rsid p SE BETA pos allele1 allele2;
   proc print data=ukb_FM_gwas(obs=1);run;
   data ukb_FM_gwas;set ukb_FM_gwas;keep chr rsid p SE BETA pos allele1 allele2;
   run;

   %end;

%else %do;

   *To save space, just exclude unnecessary columns from the dataset inmediately after its creation;
   %get_UKB_gwas_from_UKB(gwas_url=&GWAS_F_url,outdsd=ukb_F_gwas);
   proc print data=ukb_F_gwas(obs=1);run;
   data ukb_F_gwas;
   set ukb_F_gwas(rename=(pval=p SNP=rsid) where=(minor_AF>0.05 and low_confidence_variant='false'));
   keep chr rsid p SE BETA pos allele1 allele2;


   %get_UKB_gwas_from_UKB(gwas_url=&GWAS_M_url,outdsd=ukb_M_gwas);
   proc print data=ukb_M_gwas(obs=1);run;
   data ukb_M_gwas;
   set ukb_M_gwas(rename=(pval=p SNP=rsid) where=(minor_AF>0.05 and low_confidence_variant='false'));
   keep chr rsid p SE BETA pos allele1 allele2;

   %get_UKB_gwas_from_UKB(gwas_url=&GWAS_FM_url,outdsd=ukb_FM_gwas);
   proc print data=ukb_FM_gwas(obs=1);run;
   data ukb_FM_gwas;
   set ukb_FM_gwas(rename=(pval=p SNP=rsid) where=(minor_AF>0.05 and low_confidence_variant='false'));
   keep chr rsid p SE BETA pos allele1 allele2;
   run;

%end;


 /* *No need, as all gwass have numeric chroms; */
 /* %chr_format_exchanger( */
 /* dsdin=ukb_m_gwas, */
 /* char2num=1, */
 /* chr_var=chr, */
 /* dsdout=ukb_m_gwas); */

 proc datasets nolist;
    copy in=work out=FM memtype=data move;
    select ukb:; 
 run;

 *delete previous results;
 proc datasets nolist;
 delete F_vs_M_gwas;
 run;

 title "UBK &label4female_gwas gwas first 3 observations for evaluation";
 proc print data=FM.ukb_F_gwas(obs=3);run;

 *Step2: diff GWAS between Female and Male; 
 *Perform Femal vs. Male GWAS diff-zscore analysis;
 libname FM "&outdir";
 *options mprint mlogic symbolgen;
 *Note: only common SNPs will be kept;
 %DiffTwoGWAS(
 gwas1dsd=FM.ukb_F_gwas,
 gwas2dsd=FM.ukb_M_gwas,
 gwas1chr_var=chr,
 gwas1pos_var=pos,
 snp_varname=rsid,
 beta_varname=beta,
 se_varname=se,
 p_varname=P,
 gwasout=F_vs_M_gwas)
 ;
 *Release space;
 proc datasets nolist lib=FM;
 delete ukb_F_gwas ukb_M_gwas;
 run;
 *Add back two alleles into the dataset F_vs_M_gwas;
 /* proc contents data=FM.ukb_fm_gwas;run; */
 /* proc datasets;run; */
 proc sql;
 create table F_vs_M_gwas as
 select a.*,b.allele1,b.allele2,
        b.beta as FM_beta, b.se as FM_se, b.P as FM_P
 from F_vs_M_gwas as a
 left join
 FM.UKB_fm_gwas as b
 on a.rsid=b.rsid
 ;
 /* proc datasets nolist lib=FM; */
 /* delete UKB_fm_gwas; */
 proc datasets nolist;
 copy in=work out=FM memtype=data move;
 select F_vs_M_gwas;
 run;
%end;


*Export compressed GWAS data;
/* %exportds2gz( */
/* dsdin=FM.F_vs_M_gwas, */
/* outgz=F_vs_M_gwas, */
/* outdir=/home/cheng.zhong.shan/data */
/* ); */


/* Needle plot for top independent signals */
/* Get top independent signals */
*Check z-score distribution for the two GWASs;
proc print data=fm.f_vs_m_gwas(obs=10);run;
proc univariate data=fm.f_vs_m_gwas plots;
var diff_zscore gwas1_z gwas2_z;
run;

*********************Get top snps from 3 GWASs*****************;
data a;
set FM.F_vs_M_gwas;
/*Only focus on snp but not indel*/
where pval<5e-6 and index(rsid,'rs');
run;
%get_top_signal_within_dist(dsdin=a
                           ,grp_var=chr
                           ,signal_var=pval
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=10000000
                           ,dsdout=tops1);
title "Top snps from diff-zscore analysis: gwas1 for female and gwas2 for male";                           
proc print data=tops1;run;

data b;
set FM.F_vs_M_gwas;
/*Only focus on snp but not indel*/
where gwas1_p<5e-6 and index(rsid,'rs');
run;
%get_top_signal_within_dist(dsdin=b
                           ,grp_var=chr
                           ,signal_var=gwas1_p
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=10000000
                           ,dsdout=tops4female); 
title "Top snps from &label4female_gwas.-GWAS along: gwas1 for &label4female_gwas and gwas2 for &label4male_gwas";                           
proc print data=tops4female;run;

data c;
set FM.F_vs_M_gwas;
/*Only focus on snp but not indel*/
where gwas2_p<5e-6 and index(rsid,'rs');
run;
%get_top_signal_within_dist(dsdin=c
                           ,grp_var=chr
                           ,signal_var=gwas2_p
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=10000000
                           ,dsdout=tops4male);
title "Top snps from &label4male_gwas.-GWAS along: gwas1 for &label4female_gwas and gwas2 for &label4male_gwas";                            
proc print data=tops4male;run;

/* proc sql noprint; */
/* select rsid into: topsnps separated by " " */
/* from tops1 */
/* order by pval desc; */

proc sql noprint;
select rsid into: topsnps separated by " "
from tops1
order by pval desc;

%needleplot4snpsdiffzscores(
diffzscore_gwas=FM.F_vs_M_gwas,
gwas1_z=gwas1_z,
gwas2_z=gwas2_z,
snp_var=rsid,
snps=&topsnps,
diffzscore_p_var=pval,
gwas1pvar=gwas1_p,
gwas2pvar=gwas2_p,
fig_height=250,
fig_width=1900,
NotDrawBubbleBySize=0, /*Draw common bubble plot with the same size of bubbles*/
transparency4needles=0.2,
keep_snp_order4xaxis=1,
draw_p_axis_by_z_direction=&draw_p_axis_by_z_direction
);

%local_multigwas_manhattan(
GWAS_SAS_DSD=FM.F_vs_M_gwas,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Names=pval gwas1_p gwas2_p,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=&topsnps,
design_width=1900,
design_height=700,
Labels4gwas_grps=&label4f_vs_m &label4female_gwas &label4male_gwas
);
*Need to add quit to only show one figure;
quit;

/* *****************************make manhattan plot for each GWAS separately*********************************; */
/* *Use gwas1_p, gwas2_p, or pval to make local manhatton plots; */
/* %local_gwas_hits_and_nearby_sigs( */
/* GWAS_SAS_DSD=FM.f_vs_m_gwas, */
/* Marker_Col_Name=rsid, */
/* Marker_Pos_Col_Name=pos, */
/* Xaxis_Col_Name=chr, */
/* Yaxis_Col_Name=gwas1_p, */
/* GWAS_dsdout=xxx, */
/* gwas_thrsd=5.3, */
/* Mb_SNPs_Nearby=1, */
/* snps=&topsnps, */
/* design_width=2500, */
/* design_height=300 */
/* ); */
/* quit; */

********************************Draw gene tracks for top snps****************************************;

*For PAVL1;
/* %let minst=119420656; */
/* %let maxend=120020656; */
/* %let chr=11; */

/* *for ACE2; */
*chrX:15,617,961-15,618,161;
/*
%let minst=14617961;
%let maxend=16618161;
%let chr=23;

ods graphics on /reset=all;
%map_grp_assoc2gene4covidsexgwas(
gwas_dsd=FM.f_vs_m_gwas,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
dist2genes=0,
AssocPVars=pval gwas1_p gwas2_p,
ZscoreVars=diff_zscore gwas1_z gwas2_z
);
*/

*Note: both Neale UKB GWASs and GRASP GWASs use hg19 reference build;

%mend;

/*Demo 1;

*Note: this macro works for UKB GWASs from GRASP database only!;

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*UKB Female vs Male GWAS from Neale lab;
*Only works for case-control GWASs;
*http://www.nealelab.is/uk-biobank;
*https://docs.google.com/spreadsheets/d/1kvPoupSzsSFBNSztMzl04xMoSC3Kcx3CrjVf4yBmESU/edit#gid=178908679;

%UKB_Female_vs_Male_GWAS_Pipeline(
female_gwas_url=https://broad-ukb-sumstats-us-east-1.s3.amazonaws.com/round2/additive-tsvs/E4_OBESITY.gwas.imputed_v3.female.tsv.bgz,
male_gwas_url=https://broad-ukb-sumstats-us-east-1.s3.amazonaws.com/round2/additive-tsvs/E4_OBESITY.gwas.imputed_v3.male.tsv.bgz,
female_male_gwas_url=https://broad-ukb-sumstats-us-east-1.s3.amazonaws.com/round2/additive-tsvs/E4_OBESITY.gwas.imputed_v3.both_sexes.tsv.bgz ,
outdir=/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp,
forece=0,
label4female_gwas=Female,
label4male_gwas=Male,
label4f_vs_m=Female_vs_Male,
draw_p_axis_by_z_direction=1,
From_GRASP_DB=0 
);


*UK Female vs Male hospitalization GWAS;
%UKB_Female_vs_Male_GWAS_Pipeline(
female_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_EUR_F_061821.txt.gz,
male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_EUR_M_061821.txt.gz,
female_male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_EUR_061821.txt.gz,
outdir=/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp,
forece=0,
label4female_gwas=Female,
label4male_gwas=Male,
label4f_vs_m=Female_vs_Male,
draw_p_axis_by_z_direction=1 
);

*Demo 2;
*UK Female vs Male infection GWAS;
%UKB_Female_vs_Male_GWAS_Pipeline(
female_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_EUR_F_061821.txt.gz,
male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_EUR_M_061821.txt.gz,
female_male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_EUR_061821.txt.gz,
outdir=/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp,
forece=1,
label4female_gwas=Female,
label4male_gwas=Male,
label4f_vs_m=Female_vs_Male 

);

*Demo 3;
*UK AFR vs EUR infection GWAS;
*Just reuse the macro of sex-diff GWAS for AFR-EUR GWAS;
%UKB_Female_vs_Male_GWAS_Pipeline(
female_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_AFR_061821.txt.gz,
male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_EUR_061821.txt.gz,
female_male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_ALL_061821.txt.gz,
outdir=/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp,
forece=1,
label4female_gwas=AFR,
label4male_gwas=EUR,
label4f_vs_m=AFR_vs_EUR,
draw_p_axis_by_z_direction=1
);

*Demo 4;
*Just reuse the macro of diff GWAS analysis between any two GWASs;
*female is more likely to have long COVID-19;
*by comparing with male, we can find potential long COVID markders;
%UKB_Female_vs_Male_GWAS_Pipeline(
female_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/05092021/UKBB_covid19_EUR_F_050921.txt.gz,
male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/05092021/UKBB_covid19_EUR_M_050921.txt.gz,
female_male_gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_covid19_ALL_061821.txt.gz,
outdir=/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp,
forece=0,
label4female_gwas=Female,
label4male_gwas=Male,
label4f_vs_m=Female_vs_Male,
draw_p_axis_by_z_direction=1
);

*/

