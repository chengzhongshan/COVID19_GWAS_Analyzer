%macro SNP_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro*/
gwas_dsd=,
chr_var=chr,
AssocPVars=pval1 pval2,
SNP_IDs=rs370604612 rs2070788 9:5114773,
/*if providing chr:pos or chr:st:end, it will query by pos;
Please also enlarge the dist2snp to extract the whole gene body and its exons,
altought the final plots will be only restricted by the input st and end positions!*/
dist2snp=2000000,
/*in bp; left or right size distant to each target SNP for the Manhattan plot*/
SNP_Var=snp,
Pos_Var=pos,
gtf_dsd=FM.GTF_HG19,
ZscoreVars=zscore1 zscore2,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
gwas_labels_in_order=gwas1 gwas2,/*If providing _ for labeling each GWAS, 
the _ will be replaced with empty string, which is useful when wanting to remove gwas label 
if only one scatterplot or the label for a gwas containing spaces;
The list will be used to label scatterplots 
by the sub-macro map_grp_assoc2gene4covidsexgwas*/
design_width=800, 
design_height=600, 
barthickness=10, /*gene track bar thinkness*/
dotsize=6, 
dist2sep_genes=100000,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(), /*where condition to filter input gwas_dsd*/

shift_text_yval=0.1, /*in terms of gene track labels, add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis; the default value is -0.2 to put gene lable under gene tracks;
                      Change it with the macro var pct4neg_y!*/
fig_fmt=png, /*output figure formats: svg, png, jpg, and others*/
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
adjval4header=-0.2, /*In terms of header of each subscatterplot, provide postive value to move up scatter group header by the input value*/
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
SNPs2label_scatterplot_dots= /*Add multiple SNP rsids to label dots within or at the top of scatterplot
Note: if this parameter is provided, it will replace the parameter var4label_scatterplot_dots!
*/
);
*Note: the macro map_grp_assoc2gene4covidsexgwas requires the input dsd contain the var chr;
%if "&chr_var"^="chr" %then %do;
data &gwas_dsd;
set &gwas_dsd;
chr=&chr_var;
run;
%end;

*Add labels for target SNPs if they exist;
data &gwas_dsd;
set &gwas_dsd;
%if %length(&SNPs2label_scatterplot_dots)>0 %then %do;
 %let var4label_scatterplot_dots=Target_SNP;
length Target_SNP $25.;
 Target_SNP="";
 %do _si_=1 %to %ntokens(&SNPs2label_scatterplot_dots);
    if &SNP_Var="%scan(&SNPs2label_scatterplot_dots,&_si_)" then Target_SNP=&SNP_Var;
 %end;
%end;
run;

%do snpi=1 %to %ntokens(&SNP_IDs);
  *query SNP using the index snpi (do not use i that may interupt with other macro var i used other sub-macros!);
  %let qsnp=%scan(&SNP_IDs,&snpi,%str( ));
  
  *determine whether input snp is a chrpos based markder;
  %if %sysfunc(prxmatch(/:/,&qsnp)) %then %do;
    %let qsnp=%sysfunc(prxchange(s/chr//i,-1,&qsnp));
    %let chrposquery=1;
    %let num_chr=%scan(&qsnp,1,%str(:));
    %let tgt_pos=%scan(&qsnp,2,%str(:));
    
    %let st_pos=%sysevalf(&tgt_pos-&dist2snp);
    %let end_pos=%sysevalf(&tgt_pos+&dist2snp);
    
    %if %sysfunc(countc(&qsnp,%str(:)))>1 %then %do;
     /*To keep the proc sql codes consistant for creating macros vars of minst and maxend;
     The position range need to be adjusted by dist2snp, because the proc sql command
     will substract and add the dist2snp to the st and end positions; By adding and substracting
     the dist2snp from st and end position, respectively, the final minst and maxend will
     be the same as the input st and end positions!*/
     %if &dist2snp<50000000 %then %do;
      %let st_pos=%sysevalf(%scan(&qsnp,2,%str(:)) - 50000000);
      %let end_pos=%sysevalf(%scan(&qsnp,3,%str(:)) + 50000000);
     %end;
     %else %do;
      %let st_pos=%sysevalf(%scan(&qsnp,2,%str(:)) - &dist2snp);
      %let end_pos=%sysevalf(%scan(&qsnp,3,%str(:)) + &dsdt2snp);    
     %end;
    %end;
    
  %end;
  %else %do;
    %let chrposquery=0;
    %if %sysfunc(prxmatch(/^rs/i,&qsnp)) and &dist2snp<10000 %then %do;
      %put Please be noted that your query SNP is rsid (&qsnp);
      %put It is necessary to expand the searching region > +/-10kb to get genes that cover the variant and specific genes!;
      %abort 255;
    %end;
  %end;
  
  title "Query SNP is &qsnp";
  proc sql noprint;
  select &chr_var,&SNP_Var,minst,maxend
  into: chr,:snp,:minst,:maxend
  from (
  select &chr_var,&SNP_Var,&Pos_Var-&dist2snp as minst,&Pos_Var+&dist2snp as maxend
  from &gwas_dsd
  %if &chrposquery=0 %then %do;
    where &SNP_Var="&qsnp"
  %end;
  %else %do;
    where &chr_var=&num_chr and 
    (&Pos_Var between 
      &st_pos and &end_pos
    )
  %end;
  );
  %if %sysfunc(countc(&qsnp,%str(:)))=2 %then %do;
     /*To keep the proc sql codes consistant for creating macros vars of minst and maxend;
     The position range need to be adjusted by dist2snp, because the proc sql command
     will substract and add the dist2snp to the st and end positions; By adding and substracting
     the dist2snp from st and end position, respectively, the final minst and maxend will
     be the same as the input st and end positions!*/
     %let chr=%scan(&qsnp,1,%str(:));
     %let minst=%sysevalf(%scan(&qsnp,2,%str(:))-&dist2snp);
     %let maxend=%sysevalf(%scan(&qsnp,3,%str(:))+&dist2snp);    
  %end;  
  
  %if %symexist(chr)=0 %then %do;
   %put no record for your query SNP &qsnp;
   %abort 255;
  %end;
  %put Your input three parameters for the SNP &qsnp are: chr=&chr minst=&minst maxend=&maxend;

  %OpenSVG_Printer(
   filename=Local_SNP_Manhattanplot,
   svgfileref=out,
   other_paras4ods_graphics=%str(noborder)
   );

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
  gwas_labels_in_order=&gwas_labels_in_order,
  design_width=&design_width, 
  design_height=&design_height, 
  barthickness=&barthickness, 
  dotsize=&dotsize, 
  dist2sep_genes=&dist2sep_genes,
  where_cndtn_for_gwasdsd=&where_cndtn_for_gwasdsd,
  gwas_pos_var=&Pos_Var,
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
var4label_scatterplot_dots=&var4label_scatterplot_dots /*Make sure the variable name is not grp, which is a fixed var used by the macro for other purpose;
Whenever  makeheatmapdotintooneline=1 or 0, it is possible to use values of the var4label_scatterplot_dots to
label specific scatterplot dots based on the customization of the variable predifined by users for the input data set; 
default is empty; provide a variable that include non-empty strings for specific dots in the 
scatterplots;*/
  ); 
  ods printer close;
  *Also need to close the fileref out generated by the macro;
  filename out clear;
  ods listing;
  
  proc print data=&gwas_dsd;
  where &SNP_Var="&qsnp";
  run;
  
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
gwas_labels_in_order=COVID19,
design_width=800, 
design_height=600, 
barthickness=15, 
dotsize=8, 
dist2sep_genes=1000,
where_cndtn_for_gwasdsd=%str(pval<1)
);

*/

