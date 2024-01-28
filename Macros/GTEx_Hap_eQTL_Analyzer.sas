%macro GTEx_Hap_eQTL_Analyzer(
/*If there is not plink prunned snps available, please use SAS macro Haplotype_Analysis4SNPs_in_GTEx by following its demo codes*/
SNPs4Haplotype=rs7872943 rs1887428 rs1887429 rs59679286 rs5938437 rs10974914 rs1576271,	/*SNPs for haplotype eQTL analysis*/
plink_prunned_snp_file=H:\D_Queens\SASGWASDatabase\Important_Analysis_Codes\PExFInS_SAS\Databases\1KG_Phase3\JAK2_up_down_1Mb.prune.in,
/*Plink generated prune in file containing SNP rsids, which will be used for PCA analysis*/
genesymbol=JAK2,/*Target gene for haplotype eQTL analysis*/
GTEx_tissue_rgx=blood, /*regular expression without wrapping us in two forward slashes  to match target GTEx tissue for eQTL analysis at haplotype level*/
exp_hap_outdsd=exp_hap_out,
max_num_snps4PCA=500, /*Largest number of SNPs used for PCA analysis*/
drop_PCAs_and_its_snps=1, /*To simplify the final output dsd, drop SNPs used to generate these PCAs and the final PCAs*/
snp_eQTL_rst=eQTL_rst /*Output a sas dataset with the input name for SNPs included in the haplotype analysis*/
);

*Demo 1:;
*rs113819742 and rs142410894 are in high LD with rs76929059 (R2>=0.92 in AFR);
/*%let snps=rs7872943 rs1887428 rs1887429 rs59679286 rs5938437 rs10974914 rs1576271 
rs7859390 rs7034539 rs12339666 rs10974944 rs12340895 rs111793659 rs17425819 
rs7038687 rs7469563 rs7850484 rs10815157 rs17425637;*/


*Get independent SNPs for PCA analysis;
*plink -allow-no-sex --bfile Merged_1 --indep-pairwise 50 10 0.2 --out ;
*cd /d H:\D_Queens\SASGWASDatabase\Important_Analysis_Codes\PExFInS_SAS\Databases\1KG_Phase3;
*JAK2 hg19 gene body region extended +/- 1Mb: chr9:3985245-6128183;
*plink1.9 --bfile ALL_chr9_OneKG --chr 9 --from-bp 3985245 --to-bp 6128183 --indep-pairwise 50 10 0.2 --out JAK2_up_down_1Mb;
*JAK2 hg19 gene body region extended +/- 10kb: chr9:4975245-5138183;
*plink1.9 --bfile ALL_chr9_OneKG --chr 9 --from-bp 4975245 --to-bp 5228183 --indep-pairwise 50 10 0.2 --out JAK2_up_down_10kb;
*It still leaves ~8000 SNPs!, which are too many for the SAS macro to query genotypes in GTEx;
*To reduce the number of SNPs, add the filter --maf 0.05, resulting in dramatically less SNPs;
*plink1.9 --bfile ALL_chr9_OneKG --chr 9 --from-bp 3985245 --to-bp 6128183 --maf 0.05 --indep-pairwise 50 10 0.1 --out JAK2_up_down_1Mb;
*There are 295 SNPs left!;
*If further lowering --indep-pairwise to be 50 10 0.01, there will be only 114 SNPs remained!;
*The following command will restuls in 31 SNPs, which would be enough for PCA analysis;
*plink1.9 --bfile ALL_chr9_OneKG --chr 9 --from-bp 4975245 --to-bp 5228183 --indep-pairwise 50 10 0.2 --maf 0.05 --out JAK2_up_down_10kb;

proc import datafile="&plink_prunned_snp_file" 
out=snps4pca replace dbms=tab;
getnames=no;
run;

*For debugging, add (obs=10) after snps4pca;
*Default it only uses at most 500 SNPs for PCA analysis;
proc sql noprint;
select var1 into: prunned_snps separated by ' '
from snps4pca(obs=&max_num_snps4PCA);

/*%let snps=rs17425819 rs7850484 rs1887429 rs7872943 rs10974914 rs1576271 rs7859390 rs122339666 rs10974944 rs12340895 rs10815157 rs11793659 rs17425637 rs7038687 rs7469563 rs10121316 rs7850484;*/
/*%let snps=rs17425819 rs1887429;*/
/*%let snps=rs17425819 rs2564978;*/
%let snps=&SNPs4Haplotype &prunned_snps;

/*%debug_macro;*/
%Haplotype_Analysis4SNPs_in_GTEx(
query_snps=&snps,
gene=&genesymbol,
genoexp_outdsd=genos,
eQTLSumOutdsd=AssocSummary,
rgx4tissues=%bquote(&GTEx_tissue_rgx)
);
data genos_trans;
set genos_trans;
tag=_n_;
run;

%let tgt_snps=%sysfunc(prxchange(s/rs/geno_rs/,-1,&SNPs4Haplotype));
*As some SNPs are not included in GTEx, it is necessary to focus on these SNPs that exist in GTEx;
%VarnamesInDsd(indsd=genos_trans,Rgx=geno_,match_or_not_match=1,outdsd=geno_snp_ids);
proc sql noprint;
select name into: pca_snps separated by ' '
from geno_snp_ids (where = (name not in (%quotelst(&tgt_snps))));
select name into: hap_snps separated by ' '
from geno_snp_ids (where = (name in (%quotelst(&tgt_snps))));

*Need to keep the order of hap_snps as that in the &tgt_snps;
*This will ensure the final haplotypes are generated for these snps in the same order!;
*Here it is necessary to get these tgt snps in the newly created hap_snps;
*This will keep the original order of tgt snps but exclude these tgt snps used by PCA;
%let hap_snps=%list_in_list(/*a sas function keeps these query_list that exist in the base_list in the original order*/
query_list=&tgt_snps,/*blank space separated elements for querying in the following base_list*/
base_list=&hap_snps /*blank space separated elements treated as a base list to be searched for elements in the query list*/
);
%put target haplotype snps are in the following order;
%put &hap_snps;


proc hpprincomp data=genos_trans cov out=Scores noprint;
   var &pca_snps;
   id tag;
run;

title "Principle component analysis for &genesymbol SNPs";
ods graphics /reset=all;
proc sgplot data=scores;
/*scatter x=Prin1 y=Prin2;*/
scatter x=Prin1 y=Prin2;
run;
proc sgscatter data=scores;
matrix Prin1 Prin2 Prin3 Prin4 Prin5;
run;
title;

*Add PCAs into the genotype and expression data set;
proc sql;
create table genos_trans as
select *
from genos_trans %if &drop_PCAs_and_its_snps=1 %then (drop=&pca_snps);
natural join 
scores;

data genos_trans;
length id $8.;
set genos_trans;
id="S"||trim(left(put(_n_,3.)));
run;

*Now regress out effects of PCAs;
%VarnamesInDsd(indsd=genos_trans,Rgx=Prin,match_or_not_match=1,outdsd=PCA_names);
*Only use first 20 PCAs for regressing out PCA effects;
proc sql noprint;select name into: PCAs from PCA_names(obs=20);
%regress_out_covar_effects(
dsdin=genos_trans,
dsdout=genos_trans,
varadjlist= ,
modeladjlist=&PCAs,
signal_var=exp,
adjsignal_var=adj_exp
);
/*proc print data=genos_trans(obs=10);run;*/

proc sgplot data=genos_trans;
scatter x=exp y=adj_exp;
run;


%happy(indsn=genos_trans,  
       id=id,  
       keep=&hap_snps, 
       outdsn1=sample_haps,
       outdsn2=haps_frq,
       outadd=test_add
);
*Two output dsds are useful, including Haps_frq and Test_add;
*Haps_frq comprises of haplotypes with frq >0.01 and all pooled haplotype with frq <0.01;
*Test_add contains haplotype scores that can be used in proc glm for linear regression with gene expression;

proc sql;
create table &exp_hap_outdsd as
select *
from genos_trans 
natural join
test_add;
*Maintain the order of input snps;
data &exp_hap_outdsd;
retain &hap_snps;
set &exp_hap_outdsd;
run;

%if &drop_PCAs_and_its_snps=1 %then %do;
data &exp_hap_outdsd;
set &exp_hap_outdsd;
drop Prin:;
run;
%end;

*Get eQTL and allele information for tgt snps;
%rank4grps(
grps=&SNPs4Haplotype,
dsdout=_eqtls_
);
proc sql;
create table &snp_eQTL_rst as
select num_grps as hap_snp_order, 
           SNP, 
           scan(variantid,3,'_') as ref,
					 scan(variantid,4,'_') as alt,
           variantid,maf,genesymbol,nes,pvalue,gencodeId
from AssocSummary as a,
        _eqtls_ as b
where a.SNP=b.grps
order by num_grps;

*Final combined haplotype names and its frequencies;
*which can be matched with the haplotype z1-zn;
proc print data=Haps_frq;
run;

%mend;

/*Demo codes:;
*%debug_macro;

%GTEx_Hap_eQTL_Analyzer(
SNPs4Haplotype=rs7872943 rs1887428 rs1887429 rs59679286 rs5938437 rs10974914 rs1576271,
plink_prunned_snp_file=H:\D_Queens\SASGWASDatabase\Important_Analysis_Codes\PExFInS_SAS\Databases\1KG_Phase3\JAK2_up_down_1Mb.prune.in,
genesymbol=JAK2,
GTEx_tissue_rgx=Mucosa,
exp_hap_outdsd=exp_hap_out,
max_num_snps4PCA=5,
drop_PCAs_and_its_snps=1
);

proc glm data=exp_hap_out;
*consider the effect of each factor individually with ss1;
model exp=geno_: z :/ss1;
run;


%ds2csv(data=exp_hap_out,csvfile="E:\JAK2_SNPs_Hap_analysis.csv",runmode=b);

proc import datafile="E:\JAK2_SNPs_Hap_analysis.csv" dbms=csv out=x replace;
getnames=yes;guessingrows=max;
run;
%Auto_char2num4dsd( dsdin=x
,col_num_pct=0.8 
,dsdout=x1 
) ; 

data x1;
set x1;
drop exp tag;
gene_exp=adj_exp+0;
run;
proc glm data=x1;
model gene_exp=geno_:  _:;
run;


*/
