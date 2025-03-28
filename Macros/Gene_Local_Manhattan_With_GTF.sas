%macro Gene_Local_Manhattan_With_GTF(
/*
Note: comparing to the macro SNP_Local_Manhattan_With_GTF, this macro has fewer parameters to control the final figure;
If possible, please use SNP_Local_Manhattan_With_GTF to draw gene level Manhattan by providing genomic range for a target gene;

As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro;this macro will use the gene name to query GTF and GWAS, and then
make local Manhattan plot with the top SNP at the center around the query gene!
Please use the updated macro SNP_Local_Manhattan_With_GTF, which is modified to
draw figures with more customiable parameters!
*/
gwas_dsd=,
gwas_chr_var=chr,/*GTF uses numeric chr notation; ensure the type of chr is consistent with input gwas dsd*/
gwas_AssocPVars=pval1 pval2,
Gene_IDs=CD55 JAK2,
dist2Gene=50000,/*in bp; left or right size distant to each target Gene for the Manhattan plot*/
SNP_Var_GWAS=SNP,
Pos_Var_GWAS=pos,
gtf_dsd=FM.GTF_HG19,
Gene_Var_GTF=Genesymbol,
GTF_Chr_Var=chr,/*GTF uses numeric chr notation; ensure the type of chr is consistent with input gwas dsd*/
GTF_ST_Var=st,
GTF_End_Var=end,
ZscoreVars=zscore1 zscore2,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
gwas_labels_in_order=,/*scatterplot headers; if left empty, the values of &gwas_AssocPVars will be used*/
design_width=800, 
design_height=600, 
barthickness=15, /*gene track bar thinkness*/
dotsize=8, 
dist2sep_genes=1000,/*genes with distance less than the cutoff will be separated into different tracks;
In detail, this is the distance to separate close genes into different rows in the gene track; 
provide negative value to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(pval<1), /*where condition to filter input gwas_dsd
Make sure the pvalue variable is the same as one of gwas_AssocPVars*/

shift_text_yval=-0.2, /*in terms of gene track labels, add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis; the default value is -0.2 to put gene lable under gene tracks;
                      Change it with the macro var pct4neg_y!*/
fig_fmt=svg, /*output figure formats: svg, png, jpg, and others*/
pct4neg_y=2, /*the most often used value is 1;
              compacting the bed track y values by increasing the scatterplot scale, 
              which can reduce the bed trace spaces; It seems that two-fold increasement
              leads to better ticks for different tracks!
              Use value >1 will increase the gene tract, while value < 1 will reduce it!
              Note: when there are only 1 or 2 scatterplots, it is better to provide value = 0.5;
              Modify this parameter with the parameter shift_text_yval to adjust gene label!
              Typically, when there are more scatterplots, it is necessary to increase the value of pct4neg_y accordingly;
              If there are only <4 scatterplots, the value would be usually set as 1 or 2;
              */
adjval4header=-0.5, /*In terms of header of each subscatterplot, provide postive value to move up scatter group header by the input value*/

makedotheatmap=0,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot*/

color_resp_var=,/*Use value of the var to draw colormap of dots in scatterplot
if empty, the default var would be the same as that of yval_var;*/

makeheatmapdotintooneline=0,/*This will make all dots have the same yaxis value but have different colors 
based on its real value in the heatmap plot; To keep the original dot y axis value, assign 0 to the macro var
This would be handy when there are multiple subgrps represented by different y-axis values! By modifying
the y-axis values for these subgrps, the macro can plot them separately in each subtrack!
*/
var4label_scatterplot_dots= ,/*Make sure the variable name is not grp, which is a fixed var used by the macro for other purpose;
the variable should contain values of target SNPs and other non-targets are asigned with empty values;
Whenever  makeheatmapdotintooneline=1 or 0, it is possible to use values of the var4label_scatterplot_dots to
label specific scatterplot dots based on the customization of the variable predifined by users for the input data set; 
default is empty; provide a variable that include non-empty strings for specific dots in the 
scatterplots;*/
SNPs2label_scatterplot_dots=, /*Add multiple SNP rsids to label dots within or at the top of scatterplot
Note: if this parameter is provided, it will replace the parameter var4label_scatterplot_dots!
*/
text_rotate_angle=90, /*Angle to rotate text labels for these selected dots by users*/
auto_rotate2zero=1, /*supply value 1 when less than 3 text labels, it is good to automatically set the text_rotate_angel=0*/
pct2adj4dencluster=0.15,/*For SNP labels on the top, please try to use this parameter, which only works when 
there are less than or equal to 3 top SNPs if track_width <= 500, or 5 top SNPs if track_width between 500 and 800, or 6 top SNPs if 
track_width >=800, otherwise, this parameter will be excluded and even step will be used to separate them on the top!
and SNPs within a cluster are overlapped with each other or overlapped with elements from other SNP cluster, so it is feasible to 
avoid this issue by increasing the pct or reducing it, respectively*/
yoffset4max_drawmarkersontop=0.55,
Yoffset4textlabels=3.5, /*Move up the text labels for target SNPs in specific fold; 
the default value 2.5 fold works for most cases*/
adj_spaces_among_top_snps=1 /*Provide value 1 to adjust spaces among top SNP labels; otherwise, give value 0 to not 
adjust top SNPs labels if these labels are rotated 90 degree, which is helpful when the space adjusted labels are not pretty*/ 

);

*Note: it is arbitrary to have the chr var in the input gwas dsd;
*chr is used by the sub-macro map_grp_assoc2gene4covidsexgwas; 
data &gwas_dsd;
set &gwas_dsd;
chr=&gwas_chr_var;
%if %length(&SNPs2label_scatterplot_dots)>0 %then %do;
 %let var4label_scatterplot_dots=Target_SNP;
length Target_SNP $25.;
 Target_SNP="";
 %do _si_=1 %to %ntokens(&SNPs2label_scatterplot_dots);
    if &SNP_Var_GWAS="%scan(&SNPs2label_scatterplot_dots,&_si_,%str( ))" then Target_SNP=&SNP_Var_GWAS;
 %end;
%end;
run;

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
  
  %if %length(&gwas_labels_in_order)=0 %then %do;
     %put the macro var gwas_labels_in_order is empty, and the values of macro var gwas_AssocPVars will be used to label scatterplot headers;
     %let gwas_labels_in_order=&gwas_AssocPVars;
  %end;
  
  %map_grp_assoc2gene4covidsexgwas( 
  gwas_dsd=&gwas_dsd, 
  gtf_dsd=&gtf_dsd, 
  chr=&chr, 
  min_st=&minst, 
  max_end=&maxend, 
  dist2genes=1000, 
  AssocPVars=&gwas_AssocPVars, 
  ZscoreVars=&ZscoreVars, 
  gwas_labels_in_order=&gwas_labels_in_order,
  design_width=&design_width, 
  design_height=&design_height, 
  barthickness=&barthickness, 
  dotsize=&dotsize, 
  dist2sep_genes=&dist2sep_genes,
  where_cndtn_for_gwasdsd=&where_cndtn_for_gwasdsd,
  gwas_pos_var=&Pos_Var_GWAS,

  shift_text_yval=&shift_text_yval, /*in terms of gene track labels, add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis; the default value is -0.2 to put gene lable under gene tracks;
                      Change it with the macro var pct4neg_y!*/
  fig_fmt=&fig_fmt, /*output figure formats: svg, png, jpg, and others*/
  pct4neg_y=&pct4neg_y, /*the most often used value is 1;
              compacting the bed track y values by increasing the scatterplot scale, 
              which can reduce the bed trace spaces; It seems that two-fold increasement
              leads to better ticks for different tracks!
              Use value >1 will increase the gene tract, while value < 1 will reduce it!
              Note: when there are only 1 or 2 scatterplots, it is better to provide value = 0.5;
              Modify this parameter with the parameter shift_text_yval to adjust gene label!
              Typically, when there are more scatterplots, it is necessary to increase the value of pct4neg_y accordingly;
              If there are only <4 scatterplots, the value would be usually set as 1 or 2;
              */
  adjval4header=&adjval4header, /*In terms of header of each subscatterplot, provide postive value to move up scatter group header by the input value*/

  makedotheatmap=&makedotheatmap,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot*/

color_resp_var=&color_resp_var,/*Use value of the var to draw colormap of dots in scatterplot
if empty, the default var would be the same as that of yval_var;*/

makeheatmapdotintooneline=&makeheatmapdotintooneline, /*This will make all dots have the same yaxis value but have different colors 
based on its real value in the heatmap plot; To keep the original dot y axis value, assign 0 to the macro var
This would be handy when there are multiple subgrps represented by different y-axis values! By modifying
the y-axis values for these subgrps, the macro can plot them separately in each subtrack!
*/
var4label_scatterplot_dots=&var4label_scatterplot_dots, /*Make sure the variable name is not grp, which is a fixed var used by the macro for other purpose;
Whenever  makeheatmapdotintooneline=1 or 0, it is possible to use values of the var4label_scatterplot_dots to
label specific scatterplot dots based on the customization of the variable predifined by users for the input data set; 
default is empty; provide a variable that include non-empty strings for specific dots in the 
scatterplots;*/
text_rotate_angle=&text_rotate_angle, /*Angle to rotate text labels for these selected dots by users*/
auto_rotate2zero=&auto_rotate2zero, /*supply value 1 when less than 3 text labels, it is good to automatically set the text_rotate_angel=0*/
pct2adj4dencluster=&pct2adj4dencluster,/*For SNP labels on the top, please try to use this parameter, which only works when 
there are less than or equal to 3 top SNPs if track_width <= 500, or 5 top SNPs if track_width between 500 and 800, or 6 top SNPs if 
track_width >=800, otherwise, this parameter will be excluded and even step will be used to separate them on the top!
and SNPs within a cluster are overlapped with each other or overlapped with elements from other SNP cluster, so it is feasible to 
avoid this issue by increasing the pct or reducing it, respectively*/
yoffset4max_drawmarkersontop=&yoffset4max_drawmarkersontop,
Yoffset4textlabels=&Yoffset4textlabels, /*Move up the text labels for target SNPs in specific fold; 
the default value 2.5 fold works for most cases*/
adj_spaces_among_top_snps=&adj_spaces_among_top_snps /*Provide value 1 to adjust spaces among top SNP labels; otherwise, give value 0 to not 
adjust top SNPs labels if these labels are rotated 90 degree, which is helpful when the space adjusted labels are not pretty*/ 
  ); 
  *Need to delete previously generated dataset Final;
  proc datasets nolist;
/*   delete Final: _X1_ BEDCHR: Exon: X1 X2 TMP_: Single_DSD; */
  delete _X1_ BEDCHR: Exon: X1 X2 TMP_: Single_DSD;
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

