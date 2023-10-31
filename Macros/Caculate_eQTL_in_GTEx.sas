%macro Caculate_eQTL_in_GTEx(
/*Please use CaculateMulteQTLs_in_GTEx to replace this macro*/
query_snp=rs13057307,
gene=Apobec3a,
genoexp_outdsd=genoexp,
eQTLSumOutdsd=AssocSummary,
filter4geno= /*provide sas where or if condition to filter genotype data
such as %str(where geno^=0;) */
);

%QueryGTEx4GeneID(
geneids=&gene,
genomeBuild=hg38,
outdsd=gene_info
);
proc sql noprint;
select gencodeid into: ensembl_gene
from gene_info;


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

%do ti=1 %to &tottissues;
%let tissue=%scan(&tissues,&ti,%str( ));
*ENSG00000179750.15,chr22_38956748_G_A_b38: APOBEC3B;
*this snp is rare (maf<1%) in GTEx, with only 3 samples;
*have its genotype available in GTEx;
*ENSG00000128394.16,chr22_38956748_G_A_b38: APOBEC3F;

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
   proc http url=%str("&eqtl_url")
   method="get"
/*   query=("tissueSiteDetailId"="&tissue"*/
/*   "gencodeId"="&ensembl_gene"*/
/*   "variantId"="&query_snp"*/
/*   ) */
   out=G
   ;
   run;
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

proc sql;
create table geno_exp&ti as
select exp,geno,a.sample_num_id as n,1 as Total,
       "&tissue" as tissue
from geno as a,
     exp as b
where a.sample_num_id=b.sample_num_id;
drop table geno;
drop table exp;

%if %length(&filter4geno)>0 %then %do;
  data geno_exp&ti;
  set geno_exp&ti;
  &filter4geno;
  run;
%end;

title "eQTL analysis in &tissue subject to the geno filter for &query_snp: &filter4geno";
ods graphics/reset=all height=300 width=200;
proc glm data=geno_exp&ti;
model exp=geno;
lsmeans geno/pdiff;
run;

title "First 10 obs of gene_exp dataset:";
proc print data=geno_exp&ti(obs=10);run;
title "eQTL analysis of &query_snp in &tissue";
ods graphics on/reset=all height=300 width=200;
proc sgplot data=geno_exp&ti noborder nowall;
vbox exp/group=geno groupdisplay=cluster category=geno
groupdisplay=cluster boxwidth=0.8 fillattrs=(transparency=0.5) 
whiskerattrs=(pattern=2 thickness=2)
meanattrs=(symbol=circlefilled color=darkgreen size=8);
label exp="Expression of &gene" geno="Genotype of &query_snp";
xaxistable total/stat=sum class=geno position=bottom classdisplay=cluster;  
run;
title "eQTL summary for &query_snp in tissue &tissue:";
proc print data=J.root;run;	
data eqtl&ti(drop=TissueSiteDetailId);
set J.root;
length SNP $25. tissue $50.;
SNP="&query_snp";
tissue=TissueSiteDetailId;
run;
libname J clear;
filename G clear;
%end;

data &eQTLSumOutdsd;
set eqtl:;
run;

data &genoexp_outdsd;
set geno_exp:;
length SNP $25.;
SNP="&query_snp";
run;

proc datasets nolist;
delete eqtl: geno_exp:;
run

%mend;

/*Demo:
%debug_macro;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*Demo 1:;
*rs113819742 and rs142410894 are in high LD with rs76929059 (R2>=0.92 in AFR);
%Caculate_eQTL_in_GTEx(
query_snp=rs113819742,
gene=Apobec3h,
genoexp_outdsd=genoexp1,
eQTLSumOutdsd=AssocSummary1,
filter4geno=
);

*Demo2:;
%Caculate_eQTL_in_GTEx(
query_snp=rs13057307,
gene=Apobec3,
genoexp_outdsd=genoexp1,
eQTLSumOutdsd=AssocSummary1
);
*rs34074269 is high LD to rs13057307;
%Caculate_eQTL_in_GTEx(
query_snp=rs34074269,
gene=Apobec3c,
genoexp_outdsd=genoexp2,
eQTLSumOutdsd=AssocSummary2,
filter4geno=
);
*Check whether the sample number is corresponding to the same sample in the two dsd;
proc sql;
create table combined as
select a.*,b.exp as exp2,b.geno as geno2,
       b.n as n2
from genoexp1 as a
left join
genoexp2 as b
on a.tissue=b.tissue and a.exp=b.exp;

*Seems that the sample id n was randomized;
*use exp to match with each other;
proc sgplot data=combined;
where tissue="Adipose_Subcutaneous";
scatter x=exp y=exp2;
run;
*Further confirm it by evaluating its geno;
data x;
set combined;
where tissue="Adipose_Subcutaneous";
delta=n2-n;
run;
proc sort data=x;by exp;run;
proc print;run;

*/


