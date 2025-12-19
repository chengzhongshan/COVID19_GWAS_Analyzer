%macro SNP_Local_Manhattan_With_GTF(
/*Note: this macro can draw CNVs and SNVs together. Please ensure the macro variable
Variant_Length_Var is not empty, which contains distance of these CNVs (>1), with non-CNVs
assigned with missing value, and the middle positions of these CNVs is required to be 
combined with that of SNVs and gene tracks!

Tip 1: when there gene labels are cluttered within the gene track, it is feasible to 
resolve the issue by increasing the values for either variable pct4neg_y or dist2sep_genes or both!
such as pct4neg_y and dist2sep_genes=1000000; alternatively, it also possible to address the problem
by increase the width of figure, such as assigning larger value to the macro variable track_width=800.

  Tip 2: the figure width and height should ideally set around 500 and no less then 300 or greater than
1000, as large figures are not good for publication purpose! 

  Tip 3: For SNP labels on the top, please try to use this parameter, which only works when 
there are less than or equal to 3 top SNPs if track_width <= 500, or 4 top SNPs if track_width between 500 and 800, or 5 top SNPs if 
track_width >=800, otherwise, this parameter will be excluded and even step will be used to separate them on the top!

 Tip 4: dist_pct_to_cluster_pos and pct2adj4dencluste (0.0001 to ~) can affect the top SNP labels positions when there are <= 3 or 4, or 5 SNP labels, as the its value
dist_pct_to_cluster_pos will be internally replaced as 0.5/total number of top SNPs, and pct2adj4dencluste will be changed differently
when make_even_pos=1, the macro will multiple the amplification_fc with 10*pct2adj4dencluster to further enlarge the even distance among positions; 
while if make_even_pos=0, it is useful when elements within a cluster is overlapped with each other or overlapped with elements from other cluster, 
so it is also feasible to avoid this issue by increasing or reducing the pct.

 Tip 5: In default, the scatterplot will use the transformed values of all variables inclued in the macro variable
ZscoreVars into a variable for the lattice_subgrp_var to color dots differently across different scatter groups; User can supply
an independent variable represented by the macro variable color_resp_var to color scatter plot dots but different scattergroups
will be applied in a union style! 
*/

/*
As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, 
chr_var is used instead of macro var chr in this macro;*/
/*
Important: there are many other parameters of the sub-macro Lattice_gscatter_over_bed_track,
which can be modified by changing the default values for them to improve the quality of final produced figure!
*/

focus_on_transcript=0,/*This will generate a subset exon GTF data set by 
replacing gene variable with ensembl transcript variable and removing rows 
with the type of "gene" and update transcript as "gene" to enable the macro
to work on these transcripts instead of genes*/
gwas_dsd=,
chr_var=chr,
AssocPVars=pval1 pval2,
SNP_IDs=rs370604612 rs2070788 9:5114773,
/*if providing chr:pos or chr:st:end, it will query by pos;
Please also enlarge the dist2snp to extract the whole gene body and its exons,
although the final plots will be only restricted by the input start and end positions!*/
dist2snp=2000000,
/*assign value in bp, and the final figure will be add extend this distance for both start and end positions*/
SNP_Var=snp,
Pos_Var=pos,
Variant_Length_Var=,/*this variable if not empty, its value will be used to extend the value of Pos_Var for making 
the start and end position for SNP_Var, i.e., st=&Pos_Var-0.5*&Variant_Length_Var and end=&Pos_Var-0.5*&Variant_Length_Var;
This would be especially helpful for mixing CNV and SNV data for making scatter plots, as it is only necessary
to provide middle position for CNVs and its lengths for ploting CNVs and SNVs together!
*/
gtf_dsd=FM.GTF_HG19,
ZscoreVars=zscore1 zscore2,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions,
the values of which can be used to color scatter plots of association signals specifically for its corresponding scatter
plot group membership for the following gwas labels. Please ensure makedotheatmap=1 and the input zscoreVars 
are in the same type of variable that can be used properly along with the heatmap feature*/ 
gwas_labels_in_order=gwas1 gwas2,/*If providing _ for labeling each GWAS, 
the _ will be replaced with empty string, which is useful when wanting to remove gwas label 
if only one scatterplot or the label for a gwas containing spaces;
The list will be used to label scatterplots 
by the sub-macro map_grp_assoc2gene4covidsexgwas*/
design_width=500,/*Best width for publication, and usually used width rangs from 400 to 800*/ 
design_height=500,/*Best height for publication, and usally used height rangs from 400 to 800*/
barthickness=10, /*gene track bar thinkness*/
dotsize=6,/*scatter data point size for the following macro variable scattermarker_symbol*/

/*Important parameters for drawing SNVs and CNVs together*/
scattermarker_symbol=circlefilled,/*Assign specific marker symbol, such as ibeam, circlefilled, circle, dot, squarefilled, or square, for scatter plot;
Note the size of the designated marker symbol will be defined by the macro variable dotsize; when creating heatmap, you can assign
squarefilled to the scattermarker_symbol, which would be more compatable with the highlow line style in for CNV or bed regions!*/ 
highlow_line_cmd=%str(thickness=6 color=darkorange pattern=solid),/*For CNV bed regions, customize the following parameters using dot, dash, or solid line pattern 
with custome thickness and color for the line; please increase the thickness to match with that of 
dotsize=10 when scattermarker_symbol=squarefilled for the scatter plot, which will enable the square and the line
in the same size and color*/

dist2sep_genes=100000,/*Distance to separate close genes into different rows in the gene track; provide negative value or 0
to have all genes in a single row in the final gene track
this will ensure these genes close to each other to 
be separated in the final gene track; 
(1) give 0 or negative value to plot ALL genes in the same line;
(2) give value >0 and <1 to separate genes based on the pct distance to the whole region;
(3) give value > 1 to use absolute distance to separate genes into different groups;
Customize this for different gene exon track!*/
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
makedotheatmap=1,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot
Note: the macro is updated to use heatmap to illustrate positve and negative values
of scatter plot represented by the variable ZscoreVars in the sub macros
map_grp_assoc2gene4covidsexgwas=>Multgscatter_with_gene_exons (HERE inside the 1st submacro) 
=>Lattice_gscatter_over_bed_track, and you can see the details by reading the 
parameters for  the 2nd sub macro used by the 1st sub mcro;
Set it as 0 to use binary mode to color the negative and postive values in scatter plot*/

/*Main color scheme for coloring dots in scatter plot with your quantitative color response variable
Note: it is necessary to have makedotheatmap=1 and use the default heatmap_var or other quantitative
variable with both negative and positive values to color the scatter plot; when the quantitative response
variable is postive or negative, please change the heatmap_min_neg_val as 0 for postive values, meanwhile,
for all negative values, please assign value 0 to heatmap_max_pos_val*/
heatmap_var=AssocGrp,/*This variable is generated by transposing all ZscoreVars into a long format internally by the macro,
thus, do not change this macro variable, just update ZscoreVars accordingly; the macro uses this var to draw scatter plot in heatmap
with rangeattrmap instead of drawing dots using binary mode, such as 0 and 1 representing Pos
and negative directions of latticen_subgrp_var!*/
heatmap_Neg_rangealtcolormodel=darkgreen lightgreen deepskyblue,/*Range alt color model for negative values, heatmap_var<=0,  in heatmap*/
heatmap_Pos_rangealtcolormodel=gold mediumred vipk,/*Range alt color model for positve values, heatmap_var>=0, in heatmap*/
heatmap_min_neg_val=-8,/*Minimum negative value for the heatmap_var when it is not empty; 
change this to customize the minimum value for colorbar in heatmap*/
heatmap_max_pos_val=8,/*Maximum postive value for the heatmap_var when it is not empty; 
change this to customize the max value for colorbar in heatmap*/

/*Alternative color scheme for categorical color response variable! Please keep it in default
value if you don't want to use it for your quantitative color response variable*/

color_resp_var=,/*Use the variable to draw colormap of dots in scatterplots with colors
supplied by a later macro variable dataContrastCols that are specifically designated for 
scatterplot dots but not other tracks under the scatter plots, such as gene tracks;.
previously if the macro var is empty, the default var would be the same as that of yval_var;
Later it is updated to enable the macro to use lattice_subgrp_var but not yval_var when 
this color_resp_var is empty! A later macro variable dataContrastCols will be used 
to supply colors for different groups of the variable solely for coloring scatterplot dots!*/
fixedcols4tracksunderscatter=cyan blue, /*when color_resp_var is not empty, all tracks under scatterplots will be fixed with 
two different colors, including cyan and blue, represented by the macro var fixedcols4tracksunderscatter!*/
color_resp_grpdsd=,/*this dataset contains two columns, including &color_resp_var and the fixed
variable numgrp4color_resp,which are corresponding to the unique char color_resp_var and 
its associated numeric var that would be sorted to order these char color_resp_var in the final figure legend!
Note: for color_resp_var not included in the dataset, they will be asigned as Others;
Custom colors with the same number of unique color_resp_var for these groups can be provided to 
a latter macro variable dataContrastCols*/
dataContrastCols=%str(darkblue darkgreen darkred darkyellow 
CXFFF000 CXFF7F00 CXFF00FF CXFF0000 CXEAADEA CXE6E8FA CXDB9370 CXDB70DB CXD9D919 CXD8D8BF 
CXCD7F32 CXC0C0C0 CXBC8F8F CXB87333 CXB5A642 CXADEAEA CXA67D3D CXA62A2A CX9F9F5F CX9F5F9F 
CX97694F CX8E236B CX8E2323 CX8C7853 CX8C1717 CX871F78 CX856363 CX855E42 CX70DB93 CX5F9F9F 
CX5C4033 CX545454 CX4F2F4F CX4E2F2F CX32CD32 CX2F4F2F CX238E23 CX236B8E CX23238E CX00FFFF 
CX00FF00 CX0000FF CX000000
),
/*Note: these colors will be used for the scatterplot and gene track together when color_resp_var is a char var, so it is difficult control*/

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
If there are too much space on the top for these SNP labels, please manually change default value of
the macro variable yoffset4max_drawmarkersontop included in the macro Lattice_gscatter_over_bed_track
 from 0.2 to a smaller value, such as 0.1;
*/
text_rotate_angle=90, /*Angle to rotate text labels for these selected dots by users*/
auto_rotate2zero=1, /*supply value 1 when less than 3 text labels, it is good to automatically set the text_rotate_angel=0*/
pct2adj4dencluster=2,/*Input value can be ranging from 0.0001 to 10 or even higher value!
For SNP labels on the top, please try to use this parameter, which only works when 
there are less than or equal to 3 top SNPs if track_width <= 500, or 4 top SNPs if track_width between 500 and 800, or 5 top SNPs if 
track_width >=800, otherwise, this parameter will be excluded and even step will be used to separate them on the top!
and SNPs within a cluster are overlapped with each other or overlapped with elements from other SNP cluster, so it is feasible to 
avoid this issue by increasing the pct or reducing it, respectively*/
yoffset4max_drawmarkersontop=0.15, /*If draw scatterplot marker labels on the top of track, 
 this fixed value will be used instead of yaxis_offset4max!*/
Yoffset4textlabels=3.5, /*Move up the text labels for target SNPs in specific fold; 
the default value 2.5 fold works for most cases*/
adj_spaces_among_top_snps=1,/*Provide value 1 to adjust spaces among top SNP labels; otherwise, give value 0 to not 
adjust top SNPs labels if these labels are rotated 90 degree, which is helpful when the space adjusted labels are not pretty*/ 
verbose=0 /*Not print any notes in SAS log*/
);

%if &verbose=0 %then %do;
%put To prevent too many notes printed in the SAS log, we will enable options nonotes;
options nonotes;
%end;


*Note: the macro map_grp_assoc2gene4covidsexgwas requires the input dsd contain the var chr;
%if "&chr_var"^="chr" %then %do;
data &gwas_dsd;
set &gwas_dsd;
chr=&chr_var;
run;
%end;

*Add labels for target SNPs if they exist;
%if %length(&SNPs2label_scatterplot_dots)>0 %then %do;
 %let var4label_scatterplot_dots=_Target_SNP_;
data &gwas_dsd;
set &gwas_dsd;
length _Target_SNP_ $25.;
 _Target_SNP_="";
 %do _si_=1 %to %ntokens(&SNPs2label_scatterplot_dots);
    if &SNP_Var="%scan(&SNPs2label_scatterplot_dots,&_si_,%str( ))" then _Target_SNP_=&SNP_Var;
 %end;
run;
%end;

%do snpi=1 %to %ntokens(&SNP_IDs);
  *query SNP using the index snpi (do not use i that may interupt with other macro var i used other sub-macros!);
  %let qsnp=%scan(&SNP_IDs,&snpi,%str( ));
   %if %sysfunc(countc(&qsnp,%str(:)))=1 %then %do;
      *Manually add the start position as end position when the input is in the format of chrNum:Pos!;
      %let qsnp=%sysfunc(prxchange(s/^([^:]+):(\d+)/$1:$2:$2/,-1,&qsnp));
   %end;
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
/*  %abort 255;*/
  title "Local Manhattan plot for target SNP &qsnp";
  %map_grp_assoc2gene4covidsexgwas(
focus_on_transcript=&focus_on_transcript,/*This will generate a subset exon GTF data set by 
replacing gene variable with ensembl transcript variable and removing rows 
with the type of "gene" and update transcript as "gene" to enable the macro
to work on these transcripts instead of genes*/ 
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
  /*Important parameters for drawing SNVs and CNVs together*/
scattermarker_symbol=&scattermarker_symbol,/*Assign specific marker symbol, such as ibeam, circlefilled, circle, dot, squarefilled, or square, for scatter plot;
Note the size of the designated marker symbol will be defined by the macro variable dotsize; when creating heatmap, you can assign
squarefilled to the scattermarker_symbol, which would be more compatable with the highlow line style in for CNV or bed regions!*/ 
highlow_line_cmd=&highlow_line_cmd,/*For CNV bed regions, customize the following parameters using dot, dash, or solid line pattern 
with custome thickness and color for the line; please increase the thickness to match with that of 
dotsize=10 when scattermarker_symbol=squarefilled for the scatter plot, which will enable the square and the line
in the same size and color*/
  dist2sep_genes=&dist2sep_genes,
 /*this will ensure these genes close to each other to 
be separated in the final gene track; 
(1) give 0 to plot ALL genes in the same line;
(2) give value between 0 and 1 to separate genes based on the pct distance to the whole region;
(3) give value > 1 to use absolute distance to separate genes into different groups;
Customize this for different gene exon track! */
  where_cndtn_for_gwasdsd=&where_cndtn_for_gwasdsd,
  gwas_pos_var=&Pos_Var,
  Variant_Length_Var=&Variant_Length_Var,/*this variable if not empty, its value will be used to extend the value of Pos_Var for making 
the start and end position for SNP_Var, i.e., st=&Pos_Var-0.5*&Variant_Length_Var and end=&Pos_Var-0.5*&Variant_Length_Var;
This would be especially helpful for mixing CNV and SNV data for making scatter plots, as it is only necessary
to provide middle position for CNVs and its lengths for ploting CNVs and SNVs together!
*/
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

/*Main color scheme for coloring dots in scatter plot with your quantitative color response variable
Note: it is necessary to have makedotheatmap=1 and use the default heatmap_var or other quantitative
variable with both negative and positive values to color the scatter plot; when the quantitative response
variable is postive or negative, please change the heatmap_min_neg_val as 0 for postive values, meanwhile,
for all negative values, please assign value 0 to heatmap_max_pos_val*/
heatmap_var=&heatmap_var,/*Assign lattice_subgrp_var to this macro var to draw scatter plot in heatmap
using lattice_subgrp_var with rangeattrmap instead of drawing dots using binary mode, such as 0 and 1 representing Pos
and negative directions of latticen_subgrp_var!*/
heatmap_Neg_rangealtcolormodel=&heatmap_Neg_rangealtcolormodel,/*Range alt color model for negative values, heatmap_var<=0,  in heatmap*/
heatmap_Pos_rangealtcolormodel=&heatmap_Pos_rangealtcolormodel,/*Range alt color model for positve values, heatmap_var>=0, in heatmap*/
heatmap_min_neg_val=&heatmap_min_neg_val,/*Minimum negative value for the heatmap_var when it is not empty; 
change this to customize the minimum value for colorbar in heatmap*/
heatmap_max_pos_val=&heatmap_max_pos_val,/*Maximum postive value for the heatmap_var when it is not empty; 
change this to customize the max value for colorbar in heatmap*/

/*Alternative color scheme for categorical color response variable! Please keep it in default
value if you don't want to use it for your quantitative color response variable*/
color_resp_var=&color_resp_var,/*Use the variable to draw colormap of dots in scatterplots with colors
supplied by a later macro variable dataContrastCols that are specifically designated for 
scatterplot dots but not other tracks under the scatter plots, such as gene tracks;.
previously if the macro var is empty, the default var would be the same as that of yval_var;
Later it is updated to enable the macro to use lattice_subgrp_var but not yval_var when 
this color_resp_var is empty! A later macro variable dataContrastCols will be used 
to supply colors for different groups of the variable solely for coloring scatterplot dots!*/
fixedcols4tracksunderscatter=&fixedcols4tracksunderscatter, /*when color_resp_var is not empty, all tracks under scatterplots will be fixed with 
two different colors, including cyan and blue, represented by the macro var fixedcols4tracksunderscatter!*/
color_resp_grpdsd=&color_resp_grpdsd,/*this dataset contains two columns, including &color_resp_var and the fixed
variable numgrp4color_resp,which are corresponding to the unique char color_resp_var and 
its associated numeric var that would be sorted to order these char color_resp_var in the final figure legend!
Note: for color_resp_var not included in the dataset, they will be asigned as Others;
Custom colors with the same number of unique color_resp_var for these groups can be provided to 
a latter macro variable dataContrastCols*/
dataContrastCols=&dataContrastCols,
/*Note: these colors will be used for the scatterplot and gene track together when color_resp_var is a char var, so it is difficult control*/

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
pct2adj4dencluster=&pct2adj4dencluster,/*For SNP labels on the top, please try to use this parameter, which only works when there are less than or equal to 4 top SNPs 
and SNPs within a cluster are overlapped with each other or overlapped with elements from other SNP cluster, so it is feasible to 
avoid this issue by increasing the pct or reducing it, respectively*/
yoffset4max_drawmarkersontop=&yoffset4max_drawmarkersontop, /*If draw scatterplot marker labels on the top of track, 
this fixed value will be used instead of yaxis_offset4max!*/
Yoffset4textlabels=&Yoffset4textlabels, /*Move up the text labels for target SNPs in specific fold; 
the default value 2.5 fold works for most cases*/
adj_spaces_among_top_snps=&adj_spaces_among_top_snps /*Provide value 1 to adjust spaces among top SNP labels; otherwise, give value 0 to not 
adjust top SNPs labels if these labels are rotated 90 degree, which is helpful when the space adjusted labels are not pretty*/ 
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

*Reove target SNPs if they exist;
%if %length(&SNPs2label_scatterplot_dots)>0 %then %do;
data &gwas_dsd;
set &gwas_dsd;
drop _Target_SNP_;
run;
%end;

%if &verbose=0 %then %do;
%put We will enable options notes;
options notes;
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

*Demo codes to draw SNVs and CNVs together;
libname G "E:\LongCOVID_HGI_GWAS\PGC_Large_GWASs\PGC_GWAS_Analyzer_Paper\DiffGWAS4PTSD_vs_SCZ_Output";
data top_sigs;
set G.top_comm_sigs4PGC;
run;
libname FM 'E:\LongCOVID_HGI_GWAS';

%let all_snps=rs13387644;
*Note: the figure height equal to 700 and width > 700 is the best presentation of data;
data top_sigs;
set top_sigs;
*Get Z-scores for both gwass for comparable coloring of scatter plots in local Manhattan plot;
gwas1_z=gwas1_beta/gwas1_se;
gwas2_z=gwas2_beta/gwas2_se;
var_length=.;
*Make a fake CNV for each GWAS;
if rsid="rs13387644" then do;
   var_length=10000;
   gwas1_P=1e-15;
   gwas2_P=1e-15;
   pval=1e-15;
end;
run;

%SNP_Local_Manhattan_With_GTF(
gwas_dsd=top_sigs,
chr_var=chr,
AssocPVars=%pull_list(input_list=gwas1_p gwas2_p pval,idx4pull=1 2 3),
SNP_IDs=&all_snps,
dist2snp=100000,
SNP_Var=rsid,
Pos_Var=pos,
Variant_Length_Var=Var_length,
gtf_dsd=FM.GTF_HG19,
ZscoreVars=%pull_list(input_list=gwas1_z gwas2_z diff_zscore,idx4pull=1 2 3),
gwas_labels_in_order=%pull_list(input_list=PGC_Schizophrenia PGC_PTSD Schizophrenia_vs_PTSD,idx4pull=1 2 3),
design_width=950, 
design_height=800, 
barthickness=10, 
dotsize=8, 
scattermarker_symbol=circlefilled,
highlow_line_cmd=%str(thickness=8 color=darkred pattern=solid),
dist2sep_genes=20000000,
where_cndtn_for_gwasdsd=%str(),
shift_text_yval=0.2, 
fig_fmt=png,
pct4neg_y=2, 
adjval4header=-2,
makedotheatmap=1,
color_resp_var=,
makeheatmapdotintooneline=0,
var4label_scatterplot_dots= ,
SNPs2label_scatterplot_dots=&all_snps, 
yoffset4max_drawmarkersontop=0.3, 
Yoffset4textlabels=5, 
verbose=0
);

*/

