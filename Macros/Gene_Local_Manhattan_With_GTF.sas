%macro Gene_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro;
Note: this macro will use the gene name to query GTF and GWAS, and then
make local Manhattan plot with the top SNP at the center around the query gene!*/
gwas_dsd=,
gwas_chr_var=chr,
gwas_AssocPVars=pval1 pval2,
Gene_IDs=CD55 JAK2,
dist2Gene=50000,/*in bp; left or right size distant to each target Gene for the Manhattan plot*/
SNP_Var_GWAS=SNP,
Pos_Var_GWAS=pos,
gtf_dsd=FM.GTF_HG19,
Gene_Var_GTF=Genesymbol,
GTF_Chr_Var=chr,
GTF_ST_Var=st,
GTF_End_Var=end,
ZscoreVars=zscore1 zscore2,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
design_width=800, 
design_height=600, 
barthickness=15, /*gene track bar thinkness*/
dotsize=8, 
dist2sep_genes=1000,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(pval<1) /*where condition to filter input gwas_dsd*/
);

%do Genei=1 %to %ntokens(&Gene_IDs);
  *query Gene using the index Genei (do not use i that may interupt with other macro var i used other sub-macros!);
  %let qGene=%scan(&Gene_IDs,&Genei,%str( ));
  title "Macro vars: chr, Gene, st, and end for your Gene &qGene";
  proc sql;
  select &GTF_chr_var,&Gene_Var_GTF,minst,maxend
  into: chr,:Gene,:minst,:maxend
  from (
  select distinct &GTF_chr_var,&Gene_Var_GTF,
  min(&GTF_ST_Var) - &dist2Gene as minst,
  max(&GTF_End_Var) + &dist2Gene as maxend
  from &gtf_dsd
  where &Gene_Var_GTF="&qGene"
  group by &Gene_Var_GTF
  );

  %let top_snps=;
  *Get top SNP within the target region across different input AssocPvars;
  %do pvar_i=1 %to %ntokens(&gwas_AssocPvars);
    %let assoc_pvar=%scan(&gwas_AssocPvars,&pvar_i,%str( ));
    proc sql;
    create table topsnpinfo&pvar_i as
    select *
    from &gwas_dsd
    where &gwas_chr_var=&chr and 
          (&Pos_Var_GWAS between &minst and &maxend)
    group by &gwas_chr_var
    having &assoc_pvar=min(&assoc_pvar);
    
    proc sql noprint;
    select &SNP_Var_GWAS into: top_snp&pvar_i
    from topsnpinfo&pvar_i;
    
    %let top_snps=&top_snps &&top_snp&pvar_i;
    title "Top snp in your GWAS based on the p variable &assoc_pvar";
    proc print;run;
  %end;

  %put Your input three parameters for the Gene &qGene are: 
  chr: &chr, minst: &minst maxend: &maxend;
  title "
  Local Manhattan plot for target Gene &qGene with top SNP(s)(&top_snps) 
  in the order of the input GWAS pvalues
  ";
  %put You query region for the gene &qGene is %left(&chr:&minst - &maxend) (hg19);
  
  %map_grp_assoc2gene4covidsexgwas( 
  gwas_dsd=&gwas_dsd, 
  gtf_dsd=&gtf_dsd, 
  chr=&chr, 
  min_st=&minst, 
  max_end=&maxend, 
  dist2genes=1000, 
  AssocPVars=&gwas_AssocPVars, 
  ZscoreVars=&ZscoreVars, 
  design_width=&design_width, 
  design_height=&design_height, 
  barthickness=&barthickness, 
  dotsize=&dotsize, 
  dist2sep_genes=&dist2sep_genes,
  where_cndtn_for_gwasdsd=&where_cndtn_for_gwasdsd
  ); 
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
proc print data=FM.GTF_hg19(obs=2);run;
proc print data=FM.UKB_GWAS(obs=2);run;

%Gene_Local_Manhattan_With_GTF(
gwas_dsd=FM.UKB_GWAS,
gwas_chr_var=chr,
gwas_AssocPVars=pval,
Gene_IDs=TRIM21 TRIM29,
dist2Gene=500000,
SNP_Var_GWAS=SNP,
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
where_cndtn_for_gwasdsd=%str(pval<1)
);

*/

