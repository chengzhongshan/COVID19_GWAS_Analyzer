%macro GetMultQTLs4GenesInGTEx(
/*Unlike the macro CaculateMulteQTLs_in_GTEx, this macro is helpful to get genotypes and gene expression for 
multiple query SNPs and Genes at the same time; it output both long- and wide-form datasets for gene expression
corresponding to input genes, i.e., &genoexp_outdsd and &genoexp_outdsd, and the eQTL summary data set would be useful for making eQTL heatmap across
different tissues and genes for each SNP.
Note: it is necessary to set create_eqtl_boxplots=1 for obtaining the above datasets!
*/
query_snps=rs17425819 rs7850484,
genes=JAK2 CD55,
genoexp_outdsd=genos_and_exps,/*output dataset name in long format for genotype and gene expression across different tissues*/
eQTLSumOutdsd=AssocSummary,
rgx4tissues=, /*optional regular expression to select specific tissues for haplotype association;
such as (lung|liver) */

filter4geno= %str(where geno^=-1), /*put conditional filters for geno;
Need to set collect_geno4snps as 1 to be effective!*/

perform_glm=0, /*Provide value 1 to conduct proc glm for eQTL analysis;
To perform proc glm for eqtl analysis, it is needed to assign value 1 for collect_geno4snps;
Note: this is not necessary, because GTEx API does not provide PCA,
so proc glm will not be able to repeat the same eQTL association p value as that from GTEx;
*/
create_eqtl_boxplots=1,/*Provide value 1 to make boxplot for each SNP;
When setting this parameter as 1, the parameter collect_geno4snps will automatically be set as 1, too!*/

collect_geno4snps=0, /*Provide value 1 to aggregate geno for SNPs across tissues*/
heatmap_xvar=tissue,/*either SNP or tissue can be used to as x dimension group in heatmap*/
heatmap_yvar=SNP,/*either SNP or tissue can be used to as x dimension group in heatmap*/
heatmap_height=,/*eQTL heatmap height; if empty, defaut value by total number of tissue will be used*/
heatmap_width=,/*eQTL heatmap width; if empty, default value by total number of SNPs will be used*/
heatmap_fmt=png, /*make svg or png heatmap*/
boxplotpanel_width=,
boxplotpanel_height=,
tissue_eqtl_p_cutoff=1, /*To save space for heatmap and boxplot, it is better to only focus on
tissues with eQTL p lt than the cutoff*/
boxplot_colnum=6 /*this parameter decide how many tissues would be plotted in each row*/
);

%if &create_eqtl_boxplots=1 %then %do;
 %let collect_geno4snps=1;
%let collect_geno4snps=1;
%end;

%QueryGTEx4GeneID(
geneids=&genes,
genomeBuild=hg38,
outdsd=gene_info
);
proc sql noprint;
select gencodeid, geneSymbol into: ensembl_genes separated by ' ', 
                                                            :order_genes separated by ' '
from gene_info
order by geneSymbol;
%if %sysevalf(not %symexist(ensembl_genes)) %then %do;
  %put All genesymbol &genes can not be found in ensembl;
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

*Add a loop for each gene and perform eQTL analysis;
%do gi=1 %to %numargs(&order_genes);
%let gene=%scan(&order_genes,&gi,%str( ));
%let ensembl_gene=%scan(&ensembl_genes,&gi,%str( ));

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
   proc http url=%str("&eqtl_url")
   method="get"
/*   query=("tissueSiteDetailId"="&tissue"*/
/*   "gencodeId"="&ensembl_gene"*/
/*   "variantId"="&query_snp"*/
/*   ) */
   out=G;
/*    debug output_text; */
   run;
   %put &SYS_PROCHTTP_STATUS_CODE;
/*    %abort 255; */
   

%if &SYS_PROCHTTP_STATUS_CODE=200 %then %do;
   libname J json fileref=G;
   /* proc datasets lib=J; */
   /* run; */
   *There are 4 datasets, including exp data set, "Data";
   *genotype data set , "Genotypes", and eQTL summary statistics data set "Root";
   *The last data set "Alldata" combine all data sets into a long format data set;
   /* proc print data=J.ALLDATA(obs=10); */
   /* run; */

%if &collect_geno4snps=1 %then %do;

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
   create table _geno_exp&ti._snp&si as
   select exp,geno,a.sample_num_id as n,1 as Total,
          "&tissue" as tissue length=50
   from geno as a,
        exp as b
   where a.sample_num_id=b.sample_num_id;
   drop table geno;
   drop table exp;

%if &perform_glm=1 %then %do;

   %if %symexist(filter4geno) and %length(&filter4geno)>0 %then %do;
     data _geno_exp&ti._snp&si;
     set _geno_exp&ti._snp&si;
     &filter4geno;
     run;
   %end;
   
     
   title "eQTL analysis in &tissue subject to the geno filter for &query_snp: &filter4geno";
   ods graphics/reset=all height=300 width=200;
   proc glm data=_geno_exp&ti._snp&si;
   class geno;
   model exp=geno;
   lsmeans geno/pdiff;
   run;

%end;


/*   title "First 10 obs of gene_exp dataset: &query_snp";*/
/*   proc print data=_geno_exp&ti._snp&si(obs=10);run;*/

 %if &create_eqtl_boxplots=1 %then %do;
   title "eQTL analysis of &query_snp in &tissue for &gene";
   ods graphics on/reset=all height=300 width=200 imagename="T&ti._snp&si._&gi";

	*In order to make the boxplot with fixed colors for genotypes, it is necessary to sort the dataset by geno;
	proc sort data=_geno_exp&ti._snp&si;
  by geno;
  run; 

   proc sgplot data=_geno_exp&ti._snp&si noborder nowall;
   vbox exp/group=geno groupdisplay=cluster category=geno
   groupdisplay=cluster boxwidth=0.8 fillattrs=(transparency=0.5) 
   whiskerattrs=(pattern=2 thickness=2)
   meanattrs=(symbol=circlefilled color=darkgreen size=8);
   label exp="Expression of &gene" geno="Genotype of &query_snp";
   xaxistable total/stat=sum class=geno position=bottom classdisplay=cluster;  
   run;
 %end;
   data _geno_exp&ti._snp&si;
   set _geno_exp&ti._snp&si;
   length SNP $25.;
   SNP="&query_snp";
   run;
%end;
 
   title "eQTL summary for &query_snp in tissue &tissue  for &gene:";
   proc print data=J.root;run;	

   data eqtl&ti._snp&si(drop=TissueSiteDetailId rename=(genesymbol_=genesymbol));
   set J.root;
   length SNP $25. tissue $50. genesymbol_ $25.;
   SNP="&query_snp";
   genesymbol_=genesymbol;
   tissue=TissueSiteDetailId;
   drop genesymbol;
   run;

   libname J clear;
   filename G clear;
   %end; 
  %end;
%end;

data &eQTLSumOutdsd&gi;
set eqtl:;
run;

%if &collect_geno4snps=1 %then %do;
data &genoexp_outdsd&gi;
length gene $15.;
set _geno_exp:;
gene="&gene";
run;

%long2wide4multigrpsSameTypeVars(
long_dsd=&genoexp_outdsd&gi,
outwide_dsd=&genoexp_outdsd._trans&gi,
grp_vars=exp tissue gene,/*If grp_vars and SameTypeVars are overlapped,
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

%end;


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
delete eqtl: _geno_exp:;
run;

data &eQTLSumOutdsd&gi;
set &eQTLSumOutdsd&gi;
_log10P_=-log10(Pvalue);
*filter eqtl records by p cutoff;
if pValue<&tissue_eqtl_p_cutoff;
tissue=prxchange('s/^[^_]+_//',1,tissue);
tissue=prxchange('s/_/ /',-1,tissue);
label _log10P_="-log10(P)";
run;


%if %length(&heatmap_width)=0 %then %let fig_width=%sysevalf(400+20*%ntokens(&query_snps));

%if %length(&heatmap_height)=0 %then %let fig_height=%sysevalf(400+20*&tottissues);

%if &heatmap_xvar=tissue and %length(&heatmap_width)=0 and %length(&heatmap_height)=0 %then %do;
    %let htfig_width=&fig_height;
    %if htfig_width>800 %then %let htfig_width=800;
    %let htfig_height=%sysevalf(230+20*%ntokens(&query_snps));
%end;

%heatmap4longformatdsd(
/*Note: the easiest way to sort the x and y axis with customized order is to
pre-sort the dsdin according to specific xgrpvar and ygrpvar in user customized order
i.e.: proc sort data=dsdin;by xgrpvar ygrpvar;run;
These two grp vars can be generated by proc sql with specific conditions;*/
dsdin=&eQTLSumOutdsd&gi,
xvar=&heatmap_xvar,
yvar=&heatmap_yvar,
colorvar=_log10P_,
fig_height=&htfig_height,
fig_width=&htfig_width,
outline_thickness=0.5,/*Provide number > 0 to add white outline to separate each cell in heatmap*/
user_yvarfmt=,	/*default is to not use format*/
user_xvarfmt=, /*default is to not use format*/
colorbar_position=right,/*left, right, top, or bottom for gradlegend*/
colorrange=white blue red, /*color range used for heatmap*/
yfont_style=normal, /*normal or italic for yaxis font type*/
xfont_style=normal, /*normal or italic for xaxis font type*/
NotDrawYaxisLabels=0, /*Remove Yaxis labels when there are too many groups for y axis*/
NotDrawXaxisLabels=0,	 /*Remove Xaxis labels when there are too many groups for x axis*/
heatmap_fmt=&heatmap_fmt
);

*Make lattice boxplots for each SNP;

%if &create_eqtl_boxplots=1 %then %do;
%do _bs_=1 %to %ntokens(&query_snps);

%let _snp_=%scan(&query_snps,&_bs_,%str( ));
data _eqtl_summ_&_bs_._&gi;
set &eQTLSumOutdsd&gi;
*Only keep target snp and tissues with eqtl p < cutoff;
where SNP="&_snp_" and pValue<&tissue_eqtl_p_cutoff;
run;


title "eQTL boxplot for &_snp_ with gene &gene";
data snp_exp&_bs_._&gi;set &genoexp_outdsd&gi;
*Only keep target snp and tissues with eqtl p < cutoff;
where SNP="&_snp_";
tissue=prxchange('s/^[^_]+_//',1,tissue);
tissue=prxchange('s/_/ /',-1,tissue);
run;
proc sql;
create table snp_exp&_bs_._&gi as
select a.*
from snp_exp&_bs_._&gi as a,
     (select unique(tissue) from _eqtl_summ_&_bs_._&gi) as b
where a.tissue=b.tissue;

proc sql noprint;select count(unique(tissue)) into: avail_tissues_n 
from snp_exp&_bs_._&gi;
%if %length(&boxplotpanel_width)=0 %then %let boxplotpanel_width=1000;
%if %length(&boxplotpanel_height)=0 %then %let boxplotpanel_height=%sysevalf(50*&avail_tissues_n );
%if &boxplotpanel_height>3000 %then %let boxplotpanel_height=3000;


ods graphics /reset=all imagename="Boxplot_snp&si._&gi";
%boxplotbygrp(
dsdin=snp_exp&_bs_._&gi,
grpvar=geno,
valvar=exp,
panelvars=tissue,
attrmap_dsd=,
fig_height=&boxplotpanel_height,
fig_width=&boxplotpanel_width,
boxwidth=0.8,
column_num=&boxplot_colnum
);
title;

%if %ntokens(&query_snps)>1 %then %do;

%if &heatmap_xvar=tissue and %length(&heatmap_width)=0 and %length(&heatmap_height)=0 %then %do;
    %let htfig_width1=&boxplotpanel_height;
    %let htfig_height1=250;
%end;

ods graphics /reset=all imagename="heatmap_snp&si._&gi";
%heatmap4longformatdsd(
/*Note: the easiest way to sort the x and y axis with customized order is to
pre-sort the dsdin according to specific xgrpvar and ygrpvar in user customized order
i.e.: proc sort data=dsdin;by xgrpvar ygrpvar;run;
These two grp vars can be generated by proc sql with specific conditions;*/
dsdin=_eqtl_summ_&_bs_._&gi,
xvar=&heatmap_xvar,
yvar=&heatmap_yvar,
colorvar=_log10P_,
fig_height=&htfig_height1,
fig_width=&htfig_width1,
outline_thickness=0.5,/*Provide number > 0 to add white outline to separate each cell in heatmap*/
user_yvarfmt=,	/*default is to not use format*/
user_xvarfmt=, /*default is to not use format*/
colorbar_position=right,/*left, right, top, or bottom for gradlegend*/
colorrange=white blue red, /*color range used for heatmap*/
yfont_style=normal, /*normal or italic for yaxis font type*/
xfont_style=normal, /*normal or italic for xaxis font type*/
NotDrawYaxisLabels=0, /*Remove Yaxis labels when there are too many groups for y axis*/
NotDrawXaxisLabels=0,	 /*Remove Xaxis labels when there are too many groups for x axis*/
heatmap_fmt=&heatmap_fmt
);
title;
%end;

%end;
%end;
%end;

data &eQTLSumOutdsd;
set &eQTLSumOutdsd:;
run;
data &genoexp_outdsd;
set snp_exp:;
run;
data &genoexp_outdsd._trans;
set &genoexp_outdsd._trans:;
run;

*Check the SAS log, in cases of mistakenly removing other matched datasets that should be kept;
proc datasets nolist;
delete snp_exp:	  _eqtl_summ_:
%do _gi_=1 %to %eval(&gi-1);
  &eQTLSumOutdsd&_gi_
  &genoexp_outdsd._trans&_gi_
  &genoexp_outdsd&_gi_.:
%end;
 Wide_ids_lookup  _sgsort_ 	 
Dups   Fmtinfo
;
run;


%mend;

/*Demo:

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
%debug_macro;

*Demo 1:;
*rs113819742 and rs142410894 are in high LD with rs76929059 (R2>=0.92 in AFR);
%GetMultQTLs4GenesInGTEx(
query_snps=rs17425819 rs2564978,
genes=JAK2 CD55,
genoexp_outdsd=genos,
create_eqtl_boxplots=1,
eQTLSumOutdsd=AssocSummaryX,
rgx4tissues=%str(lung|blood|heart|liver|Brian)
);

*Demo2:;	
%GetMultQTLs4GenesInGTEx(
query_snps=rs13057307 rs34074269,
gene=APOBEC3A,
genoexp_outdsd=genos,
eQTLSumOutdsd=AssocSummary,
rgx4tissues=%str(lung|blood)
);

*/


