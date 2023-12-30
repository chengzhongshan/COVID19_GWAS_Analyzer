%macro Haplotype_Analysis4SNPs_in_GTEx(
query_snps=rs7850484 rs17425819,
gene=GAPDH,
genoexp_outdsd=genos,
eQTLSumOutdsd=AssocSummary,
rgx4tissues=, /*optional regular expression to select specific tissues for haplotype association;
such as (lung|liver) */
filter4geno= %str(where geno^=-1) /*put conditional filters for geno*/
);

%QueryGTEx4GeneID(
geneids=&gene,
genomeBuild=hg38,
outdsd=gene_info
);
proc sql noprint;
select gencodeid into: ensembl_gene
from gene_info;
%if %sysevalf(not %symexist(ensembl_gene)) %then %do;
  %put The genesymbol &gene can not be found in ensembl;
  %abort 255;
%end;

*Go to GTEx API website to get tissue names;
*https://gtexportal.org/api/v2/redoc#tag/Dynamic-Association-Endpoints/operation/bulk_calculate_expression_quantitative_trait_loci_api_v2_association_dyneqtl_post;
*It is necessary to query each snp for each tissue separately using GTEx API;
%let tissues=Adipose_Subcutaneous Adipose_Visceral_Omentum Adrenal_Gland Artery_Aorta 
Artery_Coronary Artery_Tibial Bladder Brain_Amygdala Brain_Anterior_cingulate_cortex_BA24 
Brain_Caudate_basal_ganglia Brain_Cerebellar_Hemisphere Brain_Cerebellum Brain_Cortex 
Brain_Frontal_Cortex_BA9 Brain_Hippocampus Brain_Hypothalamus Brain_Nucleus_accumbens_basal_ganglia Brain_Putamen_basal_ganglia Brain_Spinal_cord_cervical_c-1 Brain_Substantia_nigra Breast_Mammary_Tissue Cells_Cultured_fibroblasts Cells_EBV-transformed_lymphocytes Cells_Transformed_fibroblasts Cervix_Ectocervix Cervix_Endocervix Colon_Sigmoid Colon_Transverse 
Esophagus_Gastroesophageal_Junction Esophagus_Mucosa Esophagus_Muscularis Fallopian_Tube 
Heart_Atrial_Appendage Heart_Left_Ventricle Kidney_Cortex Kidney_Medulla Liver Lung 
Minor_Salivary_Gland Muscle_Skeletal Nerve_Tibial Ovary Pancreas Pituitary Prostate 
Skin_Not_Sun_Exposed_Suprapubic Skin_Sun_Exposed_Lower_leg Small_Intestine_Terminal_Ileum 
Spleen Stomach Testis Thyroid Uterus Vagina Whole_Blood;

%let tottissues=%sysfunc(countc(&tissues,%str( )));
%let tottissues=%sysevalf(&tottissues+1);

*filter tissues if providing rgx to match specific tissues;
/* %if %length(&rgx4tissues)>0 %then %do; */
/*   %let _tissues_=; */
/*   %do tti=1 %to &tottissues; */
/*    %if %sysfunc(prxmatch(/&rgx4tissues/,%scan(&tissues,&tti,%str( )))) %then */
/*     %let _tissues_=&_tissues_ %scan(&tissues,&tti,%str( )); */
/*   %end; */
/*   %put Your final filtered tissues are &_tissues_; */
/*   %if %length(&_tissues_)>0 %then %do; */
/*     %let tissues=&_tissues_; */
/*   %end; */
/*   %else %do; */
/*      %put No tissues matched with your regular expression!; */
/*      %abort 255; */
/*   %end; */
/* %end; */

%match_elements_in_macro_list(
macro_list=&tissues,
rgx4match=%str(&rgx4tissues),
reversematch=0,
output_idx=0, 
new_macro_list_var=_tissues_
);
*replace initial macro var tissues;
%let tissues=&_tissues_;
%let tottissues=%ntokens(&tissues);

%do ti=1 %to &tottissues;
%let tissue=%scan(&tissues,&ti,%str( ));
*ENSG00000179750.15,chr22_38956748_G_A_b38: APOBEC3B;
*this snp is rare (maf<1%) in GTEx, with only 3 samples;
*have its genotype available in GTEx;
*ENSG00000128394.16,chr22_38956748_G_A_b38: APOBEC3F;

 %do si=1 %to %ntokens(&query_snps);
   %let query_snp=%scan(&query_snps,&si,%str( ));
   *query eQTL via GTEx API;
   filename G temp;
 /*Due to local SAS9.4 in Windows can not use query in proc http, we need to input these query parameters into the url directly*/
/*   %let eqtl_url=https://gtexportal.org/api/v2/association/dyneqtl;*/
    %let eqtl_url=%nrstr(https://gtexportal.org/api/v2/association/dyneqtl?tissueSiteDetailId=)&tissue%nrstr(&gencodeId=)&ensembl_gene%nrstr(&variantId=)&query_snp;
   *The snp rs12168809 and rs76929059 is not included in GTEx;
   *Focus on rs13057307 and rs2076109;
   *rs2076109 is not an eQTL for APOBEC3B, ENSG00000179750.15, or APOBEC3A in while blood;
   *APOBEC3A: ENSG00000128383.12;
   *APOBEC3C: ENSG00000244509.3;
   *APOBEC3D: ENSG00000243811.8;
   *APOBEC3F: ENSG00000128394.16;
   *APOBEC3G: ENSG00000239713.8;
   *APOBEC3H: ENSG00000100298.15;
   *rs13057307 is an eQTL for many APOBEC3 genes;
   *The proc http using the method and query functions, which are unavailable in local SAS9.4;
   proc http url=%str("&eqtl_url")
   method="get"
/*   query=("tissueSiteDetailId"="&tissue"*/
/*   "gencodeId"="&ensembl_gene"*/
/*   "variantId"="&query_snp"*/
/*   ) */
   out=G
   ;
   run;
 %if &SYS_PROCHTTP_STATUS_CODE=200 %then %do;
   libname J json fileref=G;
   /* proc datasets lib=J; */
   /* run; */
   *There are 4 datasets, including exp data set, "Data";
   *genotype data set , "Genotypes", and eQTL summary statistics data set "Root";
   *The last data set "Alldata" combine all data sets into a long format data set;
   /* proc print data=J.ALLDATA(obs=10); */
   /* run; */
   data geno(keep=geno sample_num_id);
   set J.Alldata(where=(P1="genotypes"));
   sample_num_id=prxchange("s/genotypes//",-1,P2)+0;
   geno=value+0;
   if geno^=.;
   run;
   %if %sysfunc(exist(geno))=0 %then %do;
   %put no data for the SNP &query_snp;
   %abort 255;
   %end;

   data exp(keep=exp sample_num_id);
   set J.Alldata(where=(P1="data"));
   sample_num_id=prxchange("s/data//",-1,P2)+0;
   exp=value+0;
   if exp^=.;
   run;

/*   %abort 255;*/

   proc sql;
   create table geno_exp&ti._snp&si as
   select exp,geno,a.sample_num_id as n,1 as Total,
          "&tissue" as tissue length=50
   from geno as a,
        exp as b
   where a.sample_num_id=b.sample_num_id;
   drop table geno;
   drop table exp;

   %if %symexist(&filter4geno) and %length(&filter4geno)>0 %then %do;
     data geno_exp&ti._snp&si;
     set geno_exp&ti._snp&si;
     &filter4geno;
     run;
     title "eQTL analysis in &tissue subject to the geno filter: &filter4geno";
     proc glm data=geno_exp&ti._snp&si;
     model exp=geno;
     lsmeans geno/pdiff;
     run;
   %end;


   title "First 10 obs of gene_exp dataset: &query_snp";
   proc print data=geno_exp&ti._snp&si(obs=10);run;
 *It is necessary to change imagename for different SNPs, otherwise the figure will be the same for all SNPs;
   ods graphics on/reset=all height=300 width=200 imagename="geno_exp&ti._snp&si";
  title "eQTL analysis of &query_snp in &tissue";

   proc sgplot data=geno_exp&ti._snp&si noborder nowall;
   vbox exp/group=geno groupdisplay=cluster category=geno
   groupdisplay=cluster boxwidth=0.8 fillattrs=(transparency=0.5) 
   whiskerattrs=(pattern=2 thickness=2)
   meanattrs=(symbol=circlefilled color=darkgreen size=8);
   label exp="Normalized expression of &gene" geno="Genotype of &query_snp";
   xaxistable total/stat=sum class=geno position=bottom classdisplay=cluster;  
   run;

   title "eQTL summary for &query_snp in tissue &tissue:";
   proc print data=J.root;run;	

   data eqtl&ti._snp&si(drop=TissueSiteDetailId);
   set J.root;
   length SNP $25. tissue $50.;
   SNP="&query_snp";
   tissue=TissueSiteDetailId;
   run;
   libname J clear;
   filename G clear;
   
   data geno_exp&ti._snp&si;
   length SNP $20.;
   set geno_exp&ti._snp&si;
   SNP="&query_snp";
   run;
   %end;
  %end;
%end;

data &eQTLSumOutdsd;
set eqtl:;
run;

data &genoexp_outdsd;
set geno_exp:;
run;

%long2wide4multigrpsSameTypeVars(
long_dsd=&genoexp_outdsd,
outwide_dsd=&genoexp_outdsd._trans,
grp_vars=exp tissue,/*If grp_vars and SameTypeVars are overlapped,
the macro will automatically only keep it in the grp_vars; 
grp_vars can be multi vars separated by space, which 
can be numeric and character*/
subgrpvar4wideheader=SNP,/*This subgrpvar will be used to tag all transposed SameTypeVars 
in the wide table, and the max length of this var can not be >32!*/
dlm4subgrpvar=.,/*string used to split the subgrpvar if it is too long*/
ithelement4subgrpvar=1,/*Keep the nth splitted element of subgrpvar and use it for tag 
in the final wide table*/
SameTypeVars=geno, /*These same type of vars will be added with subgrp tag in the 
final wide table; Make sure they are either numberic or character vars and not 
overlapped with grp_vars and subgrpvar!*/
debug=0 /*print the first 2 records for the final wide format dsd*/
);
/* proc sgplot data=genos_trans; */
/* scatter x=geno_rs17425819 y=geno_rs7850484/group=tissue; */
/* run; */
/* proc sort data=genos_trans;by tissue; */
/* proc corr data=genos_trans; */
/* var geno_rs17425819; */
/* with geno_rs7850484; */
/* by tissue; */
/* run; */

proc datasets nolist;
delete eqtl: geno_exp:;
run

%mend;

/*Demo:

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
%debug_macro;

*Demo 1:;
*rs113819742 and rs142410894 are in high LD with rs76929059 (R2>=0.92 in AFR);
%let snps=rs7872943 rs1887428 rs1887429 rs59679286 rs5938437 rs10974914 rs1576271 rs7859390 rs7034539 rs12339666 rs10974944 rs12340895 rs111793659 rs17425819 rs7038687 rs7469563 rs7850484 rs10815157 rs17425637;
%Haplotype_Analysis4SNPs_in_GTEx(
query_snps=&snps,
gene=GAPDH,
genoexp_outdsd=genos,
eQTLSumOutdsd=AssocSummary,
rgx4tissues=%str(lung)
);
data genos_trans;
length id $8.;
set genos_trans;
id="S"||trim(left(put(_n_,3.)));
run;
%ds2csv(data=genos_trans,csvfile=%sysfunc(pathname(HOME))/geno_trans.csv,runmode=b);

x cd "E:\JAK2_New_papers";
proc import datafile="geno_trans_GTEx.csv" dbms=csv out=genos_trans replace;
run;
*Run it in local computer, as the proc haplotype is available;
%VarnamesInDsd(indsd=genos_trans,Rgx=geno_,match_or_not_match=1,outdsd=geno_snps);
proc sql noprint;select name into: geno_snp_ids separated by ' ' 
from geno_snps;
%happy(indsn=genos_trans,  
       id=id,  
       keep=&geno_snp_ids, 
       outdsn2=test_haps,
       outadd=test_add
);


*/


