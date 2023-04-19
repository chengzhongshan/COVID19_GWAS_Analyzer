%macro SNP_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro*/
gwas_dsd=,
chr_var=chr,
AssocPVars=pval1 pval2,
SNP_IDs=rs370604612 rs2070788,
dist2snp=50000,/*in bp; left or right size distant to each target SNP for the Manhattan plot*/
SNP_Var=snp,
Pos_Var=pos,
gtf_dsd=FM.GTF_HG19,
ZscoreVars=zscore1 zscore2,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
design_width=800, 
design_height=600, 
barthickness=15, /*gene track bar thinkness*/
dotsize=8, 
dist2sep_genes=1000,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(pval<1) /*where condition to filter input gwas_dsd*/
);

%do snpi=1 %to %ntokens(&SNP_IDs);
  *query SNP using the index snpi (do not use i that may interupt with other macro var i used other sub-macros!);
  %let qsnp=%scan(&SNP_IDs,&snpi,%str( ));
  title "Macro vars: chr, snp, st, and end for your SNP &qsnp";
  proc sql;
  select &chr_var,&SNP_Var,minst,maxend
  into: chr,:snp,:minst,:maxend
  from (
  select &chr_var,&SNP_Var,&Pos_Var-&dist2snp as minst,&Pos_Var+&dist2snp as maxend
  from &gwas_dsd
  where &SNP_Var="&qsnp"
  );

  %put Your input three parameters for the SNP &qsnp are: chr=&chr minst=&minst maxend=&maxend;
  title "Local Manhattan plot for target SNP &qsnp";
  %map_grp_assoc2gene4covidsexgwas( 
  gwas_dsd=&gwas_dsd, 
  gtf_dsd=&gtf_dsd, 
  chr=&chr, 
  min_st=&minst, 
  max_end=&maxend, 
  dist2genes=1000, 
  AssocPVars=&AssocPVars, 
  ZscoreVars=&ZscoreVars, 
  design_width=&design_width, 
  design_height=&design_height, 
  barthickness=&barthickness, 
  dotsize=&dotsize, 
  dist2sep_genes=&dist2sep_genes,
  where_cndtn_for_gwasdsd=&where_cndtn_for_gwasdsd,
  gwas_pos_var=&Pos_Var
  ); 
  proc print data=&gwas_dsd;
  where &SNP_Var="&qsnp";
  run;
  *Need to delete previously generated dataset Final;
  proc datasets nolist;
  delete Final: _X1_ BEDCHR: Exon: X1 X2 TMP_: Single_DSD;
  run;
  title;
  
%end;

%mend;

/*Demo:

*options mprint mlogic symbolgen;

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

%SNP_Local_Manhattan_With_GTF(
gwas_dsd=FM.UKB_GWAS,
chr_var=chr,
AssocPVars=pval,
SNP_IDs=rs17513063 rs370604612,
dist2snp=50000,
SNP_Var=snp,
Pos_Var=pos,
gtf_dsd=FM.GTF_HG19,
ZscoreVars=beta,
design_width=800, 
design_height=600, 
barthickness=15, 
dotsize=8, 
dist2sep_genes=1000,
where_cndtn_for_gwasdsd=%str(pval<1)
);

*/

