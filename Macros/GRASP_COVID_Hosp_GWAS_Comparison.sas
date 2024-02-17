%macro GRASP_COVID_Hosp_GWAS_Comparison(
gwas1=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B1_ALL_20201020.b37.txt.gz,
gwas2=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz,
outdir=%sysfunc(pathname(HOME)), /*SAS GWAS data sets, GWAS1, GWAS2, and GWAS1_vs_2 will be output into the dir*/
mk_manhattan_qqplots4twoGWASs=0, /*Generate GWAS manhattan and qq plots*/
maf_cutoff=0.01 /*MAF cutoff of SNPs from both GWASs*/
);

%if %sysfunc(prxmatch(/https/,&gwas1)) %then %do;
  *Note: sas will automatically treats newline as space when creating a macro var;
  %let gwas1=%sysfunc(prxchange(s/ //,-1,&gwas1));
  %put GWAS1 url link is updated by removing spaces and newlines as &gwas1;
%end;

%if %sysfunc(prxmatch(/https/,&gwas2)) %then %do;
  %let gwas2=%sysfunc(prxchange(s/ //,-1,&gwas2));
  %put GWAS2 url link is is updated by removing spaces and newlines as &gwas2;
%end;

libname D "&outdir";

/* proc print data=D.GWAS2; */
/* where rsid="rs16831827"; */
/* run; */

%let gwas_url=&gwas1;
%get_HGI_covid_gwas_from_grasp(gwas_url=&gwas_url,outdsd=GWAS1);
/* %debug_macro; */
data g1;
set GWAS1;
where p<1e-7;
run;

*****************************************************;
/* data a; */
/* set D.HGI_B1_vs_B2; */
/* Only focus on snp but not indel */
/* where pval<5e-5 and index(rsid,'rs'); */
/* run; */

%get_top_signal_within_dist(dsdin=g1
                           ,grp_var=chr
                           ,signal_var=p
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=10000000
                           ,dsdout=tops1);
proc sql noprint;
select trim(left(rsid)) into: tgt_snps1 separated by ' '
from tops1;
select count(rsid) into: top_tot1
from tops1;

%if &top_tot1>1 %then %do;

%do _snpi_=3 %to %sysevalf(3+&top_tot1) %by 3;
%let slcted_snps1=%sysfunc(prxchange(s/^(\s?\S+\s?){%sysevalf(&_snpi_-3)}((\S+\s?){3}).*/\2/,-1,&tgt_snps1));
%put &slcted_snps1;

title "Top GWAS hits from the first GWAS";
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.GWAS1,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=%str(&slcted_snps1),
design_width=%sysevalf(300*%ntokens(&slcted_snps1)),
design_height=300,
col_or_row_lattice=1 /*Plot each subplot in a single column or row:
                      1: columnlattice; 0: rowlattice*/
);
title;
%end;
%end;

%let gwas_url=&gwas2;
%get_HGI_covid_gwas_from_grasp(gwas_url=&gwas_url,outdsd=GWAS2);
data g2;
set GWAS2;
where p<1e-7;
run;

*****************************************************;
/* data a; */
/* set D.HGI_B1_vs_B2; */
/* Only focus on snp but not indel */
/* where pval<5e-5 and index(rsid,'rs'); */
/* run; */

%get_top_signal_within_dist(dsdin=g2
                           ,grp_var=chr
                           ,signal_var=p
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=10000000
                           ,dsdout=tops2);
proc sql noprint;
select trim(left(rsid)) into: tgt_snps2 separated by ' '
from tops2;
select count(rsid) into: top_tot2
from tops2;

%if &top_tot2>1 %then %do;
%do _snpii_=3 %to %sysevalf(3+&top_tot2) %by 3;
%let slcted_snps2=%sysfunc(prxchange(s/^(\s?\S+\s?){%sysevalf(&_snpii_-3)}((\S+\s?){3}).*/\2/,-1,&tgt_snps2));
%put &slcted_snps2;

title "Top GWAS hits from the second GWAS";
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.GWAS2,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx2,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=%str(&slcted_snps2),
design_width=%sysevalf(300*%ntokens(&slcted_snps2)),
design_height=300,
col_or_row_lattice=1 /*Plot each subplot in a single column or row:
                      1: columnlattice; 0: rowlattice*/
);
title;
%end;
%end;


data GWAS1;set GWAS1;where AF>&maf_cutoff;run;
data GWAS2;set GWAS2;where AF>&maf_cutoff;run;


/*
proc print data=D.GWAS2(obs=10);
%print_nicer;
run;
*/

/*
proc datasets nolist;
copy in=D out=work memtype=data move;
select HGI_B:;
run;
*/

*options mprint mlogic symbolgen;
%DiffTwoGWAS(
gwas1dsd=GWAS1,
gwas2dsd=GWAS2,
gwas1chr_var=chr,
gwas1pos_var=pos,
snp_varname=rsid,
beta_varname=beta,
se_varname=se,
p_varname=P,
gwasout=GWAS1_vs_2,
allele1var=ref,
allele2var=alt,
mk_manhattan_qqplots4twoGWASs=&mk_manhattan_qqplots4twoGWASs
);

proc datasets nolist;
copy in=work out=D memtype=data move;
select GWAS1 GWAS2 GWAS1_vs_2;
run;

libname D clear;

%mend;

/*Demo code:;

%include "%sysfunc(pathname(HOME))/Macros/importallmacros_ue.sas";
%importallmacros_ue;
*%debug_macro;
%GRASP_COVID_Hosp_GWAS_Comparison(
gwas1=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B1_ALL_20201020.b37.txt.gz,
gwas2=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz,
outdir=%sysfunc(pathname(HOME)),
mk_manhattan_qqplots4twoGWASs=1 
);

libname D "%sysfunc(pathname(HOME))";
proc print data=D.GWAS1_vs_2(obs=10);
run;
proc sort data=D.GWAS1_vs_2;by chr pos;run;
%Manhattan4DiffGWASs(
dsdin=D.GWAS1_vs_2,
pos_var=pos,
chr_var=chr,
P_var=GWAS1_P,
Other_P_vars=GWAS2_P Pval,
logP=1,
gwas_thrsd=7.3,
dotsize=2,
_logP_topval=10
);

*Single GWAS Manhattan plot;
%manhattan(dsdin=D.GWAS1_vs_2,
           pos_var=Pos,
           chr_var=Chr,
           P_var=Pval,
           logP=1);

*/

