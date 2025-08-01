/*
UKBB		06.18.21		Hospitalized Positive vs. Non-Hospitalized Positive or Negative or Untested		1,343 / 262,886		Mixed		F		47.88M		395		Summary Stats		Annotated		Grasp		EBI		GTeX		eQLdb		
UKBB		06.18.21		Hospitalized Positive vs. Non-Hospitalized Positive or Negative or Untested		1,917 / 221,174		Mixed		M		47.45M		531		Summary Stats		Annotated		Grasp		EBI		GTeX		eQLdb		
https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_ALL_F_061821.txt.gz
https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_ALL_M_061821.txt.gz
*/



*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname D '/home/cheng.zhong.shan/data';


 *Step 1: for Mixed samples, check the sex specific association signals with Covid19 hospitalization; 
 %let GWAS_F_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_ALL_F_061821.txt.gz; 
 %let GWAS_M_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_ALL_M_061821.txt.gz; 
 %let GWAS_FM_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/06182021/UKBB_hsptl_ALL_061821.txt.gz; 

%get_covid_gwas_from_grasp(gwas_url=&GWAS_F_url,outdsd=ukb_F_mixed);
%get_covid_gwas_from_grasp(gwas_url=&GWAS_M_url,outdsd=ukb_M_mixed);
/* %get_covid_gwas_from_grasp(gwas_url=&GWAS_FM_url,outdsd=ukb_FM_mixed); */

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';


proc print data=ukb_F_mixed(obs=1);run;
data ukb_F_mixed;set ukb_F_mixed;keep chr rsid p SE BETA pos allele1 allele2;
proc print data=ukb_M_mixed(obs=1);run;
data ukb_M_mixed;set ukb_M_mixed;keep chr rsid p SE BETA pos allele1 allele2;
/* proc print data=ukb_FM_mixed(obs=1);run; */
/* data ukb_FM_mixed;set ukb_FM_mixed;keep chr rsid p SE BETA pos allele1 allele2; */
/* run; */


*Step2: diff GWAS between Female and Male; 
*Perform Femal vs. Male GWAS diff-zscore analysis;
/*libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';*/

*options mprint mlogic symbolgen;
proc datasets nolist;
copy in=D out=work memtype=data;
select UKB:;
run;
%DiffTwoGWAS(
gwas1dsd=ukb_F_mixed,
gwas2dsd=ukb_M_mixed,
gwas1chr_var=chr,
gwas1pos_var=pos,
snp_varname=rsid,
beta_varname=beta,
se_varname=se,
p_varname=P,
gwasout=F_vs_M_MixedPop)
;

%Manhattan4DiffGWASs(
dsdin=F_vs_M_MixedPop,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=chr,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=gwas1_P,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=gwas2_P pval, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=2,/*The dot size for scatter plots*/
_logP_topval=10, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=5,
fig_width=1200,
fig_height=500,
fontsize=4,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=,
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three, /*a prefix used to label the output figure*/
angle4xaxis_label=0, 
Use_scaled_pos=1,
sep_chr_grp=0,
xgrp_y_pos=0,
yoffset_setting=%str( )
);


proc datasets nolist;
copy in=work out=D memtype=data move;
select ukb_F_mixed ukb_M_mixed F_vs_M_MixedPop;
run;

proc sql;
select count(*)
from D.F_vs_M_MixedPop;


********************************Start here**************************;
/* Needle plot for top independent signals */
/* Get top independent signals */
*options mprint mlogic symbolgen;

libname D '/home/cheng.zhong.shan/data';

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

data _tops_;
set D.tops;
*Because rs190509934 does not exist in the UKB sex stratified GWASs;
*Use SNP rs2106809 for further investigation;
if rsid="rs190509934" then rsid="rs2106809";
run;
proc sql;
create table ThreeGWASs_Sub as
select a.*,b.grp,b.rsid as tag_snp
from _tops_ as b
left join 
D.F_vs_m_mixedpop as a
on a.chr=b.chr and (a.pos between b.pos - 5e5 and b.pos+5e5);

data ThreeGWASs_Sub_hosp ThreeGWASs_Sub_nonhosp;
set ThreeGWASs_Sub;
if grp="Hosp" then output ThreeGWASs_Sub_hosp;
else output ThreeGWASs_Sub_nonhosp;
run;

*Prepare a table looking up chrs and colors;
data chr_colors;
input cls $8.;
chr=_n_;
cards;
cx0072bd
cxd95319
cxedb120
cx7e2f8e
cx77ac30
cx4dbeee
cxa2142f
cx0072bd
cxd95319
cxedb120
cx7e2f8e
cx77ac30
cx4dbeee
cxa2142f
cx0072bd
cxd95319
cxedb120
cx7e2f8e
cx77ac30
cx4dbeee
cxa2142f
cx0072bd
cxd95319
;
run;
proc sort data=ThreeGWASs_Sub_nonhosp(keep=chr tag_snp) out=nonhosp_snps nodupkeys;
by chr tag_snp;
run;
proc sql;
create table nonhosp_snps as
select a.*,b.cls
from nonhosp_snps as a
left join
chr_colors as b
on a.chr=b.chr;
select cls into: nonhosp_chr_colors separated by ' '
from nonhosp_snps 
order by tag_snp;

proc sort data=ThreeGWASs_Sub_hosp(keep=chr tag_snp) out=hosp_snps nodupkeys;
by chr tag_snp;
run;
proc sql noprint;
create table hosp_snps as
select a.*,b.cls
from hosp_snps as a
left join
chr_colors as b
on a.chr=b.chr;
select cls into: hosp_chr_colors separated by ' '
from hosp_snps 
order by tag_snp;

/*%debug_macro;*/

%Manhattan4DiffGWASs(
dsdin=ThreeGWASs_Sub_nonhosp,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=tag_snp,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=gwas1_P,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=gwas2_P pval, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=8, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=5,
fig_width=1000,
fig_height=700,
fontsize=2,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=&nonhosp_chr_colors,
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three, /*a prefix used to label the output figure*/
angle4xaxis_label=90, 
Use_scaled_pos=1,
sep_chr_grp=1,
xgrp_y_pos=0,
yoffset_setting=%str(offset=(15,0))
);
ods html image_dpi=300;
ods graphics on/reset=all;
%Manhattan4DiffGWASs(
dsdin=ThreeGWASs_Sub_hosp,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=tag_snp,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=gwas1_P,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=gwas2_P pval, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=8, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=5,
fig_width=1200,
fig_height=700,
fontsize=2,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=&hosp_chr_colors,
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three, /*a prefix used to label the output figure*/
angle4xaxis_label=90, 
Use_scaled_pos=1,
sep_chr_grp=1,
xgrp_y_pos=0,
yoffset_setting=%str(offset=(15,0))
);


data tops(drop=grp);
set ThreeGWASs_Sub;
type=grp;
run;
*lookup these SNPs with gene names and combine rsid and gene name as final y-axis tickets;
proc import datafile="top_snp2gene.csv"
dbms=csv out=snp2gene replace;
getnames=yes;guessingrows=max;
run;

*Not good to use combined rsid and gene name for labeling the y-axis;
/*
proc sql;
create table tops as
select a.*,catx(': ',b.gene,cats('^',a.rsid)) as ylble
from tops as a
left join 
snp2gene as b
on a.rsid=b.rsid;

data tops;
length rsid $30.;
set tops;
rsid=ylble;
*/
proc sql;
create table tops as
select a.*,b.gene
from tops as a
inner join 
snp2gene as b
on a.rsid=b.rsid;

*This would be helpful if it is necessary to sort the SNPs by SNP type and effect size beta;
proc sort data=tops;by type gwas2_beta rsid;run;

*This will only sort by SNP type and rsid;
/*proc sort data=tops;by type rsid;run;*/

%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=gwas1_beta, 
se_var=gwas1_se, 
sig_p_var=gwas1_p,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_B1, 
outdsd=dsd4ORs,
figfmt=png,
figwidth=900,
figheight=1400, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);
data dsd4ORs1;
set dsd4ORs;
gwas="Female";
abs_beta=abs(log(effect));
proc glm data=dsd4ORs1;
class type;
model abs_beta=type;
run;


*Try to generate figure for flipping x and y axis;
%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=gwas1_beta, 
se_var=gwas1_se, 
sig_p_var=gwas1_p,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_B1, 
outdsd=dsd4ORs,
figfmt=png,
figwidth=600,
figheight=2000, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);
data dsd4ORs2;
set dsd4ORs;
gwas="Male";
abs_beta=abs(log(effect));
proc glm data=dsd4ORs2;
class type;
model abs_beta=type;
lsmeans type/pdiff;
run;

data Combined_effs;
length type $15. gwas $8. groups $30.;
set dsd4ORs1(keep=gwas type abs_beta)
dsd4ORs2(keep=gwas type abs_beta);
if type="Hosp" then type="Category 1";
else type="Category 2";
label type="Potential long COVID SNPs"
abs_beta="Absolute effect size beta";
groups=catx("_",gwas,type);
run;
proc sort data=Combined_effs;
by gwas type;
run;
ods html image_dpi=300;
%boxplotbygrp(
dsdin=Combined_effs,
grpvar=type,
valvar=abs_beta,
panelvars=gwas,
attrmap_dsd=,
fig_height=500,
fig_width=1000,
transparency=0.3,
boxwidth=0.5,
column_num=3
);
proc glm data=Combined_effs;
class groups;
model abs_beta=groups;
lsmeans groups/pdiff adjust=tukey;
run;

%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=gwas2_beta, 
se_var=gwas2_se, 
sig_p_var=gwas2_p,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_B1, 
figfmt=png,
figwidth=900,
figheight=1400, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);

*Try to generate figure for flipping x and y axis;
%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=gwas2_beta, 
se_var=gwas2_se, 
sig_p_var=gwas2_p,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_B1, 
figfmt=png,
figwidth=600,
figheight=2000, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-2 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);

***************************Codes for generating local Manhattan plots for top potential long COVID SNPs in the sex-biased COVID-19 GWASs***************;
data ThreeGWASs;
set D.F_vs_m_mixedpop;
drop frq;
run;
%ds2csv(data=threeGWASs,csvfile=%sysfunc(pathname(HOME))/UKB_Sex_diff_GWAS_Mixed.csv,runmode=b);


%let tgt_snps=rs5023077 rs75432325 rs505922 rs2897075 rs17078348  rs12660421 rs79611697 rs7515509 rs76608815 
rs12585036 rs5023077 rs2834164 rs1634761 rs7251000 rs11766643 rs7684660;
*%let tgt_snps=rs5023077 rs2897075 rs7515509 rs76608815 rs7684660 rs11766643;
/*%let tgt_snps=rs7515509;*/
*For 	rs5023077 of FBRSL1;
%SNP_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro*/
gwas_dsd=ThreeGWASs,
chr_var=chr,
AssocPVars=gwas2_p gwas1_p pval,
SNP_IDs=	&tgt_snps,
/*if providing chr:pos or chr:st:end, it will query by pos;
Please also enlarge the dist2snp to extract the whole gene body and its exons,
altought the final plots will be only restricted by the input st and end positions!*/
dist2snp=250000,
/*in bp; left or right size distant to each target SNP for the Manhattan plot*/
SNP_Var=rsid,
Pos_Var=pos,
gtf_dsd=FM.GTF_HG19,
ZscoreVars=gwas1_beta gwas2_beta diff_zscore,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
gwas_labels_in_order=Male Female Femal_vs._Male,/*If providing _ for labeling each GWAS, 
the _ will be replaced with empty string, which is useful when wanting to remove gwas label 
if only one scatterplot or the label for a gwas containing spaces;
The list will be used to label scatterplots 
by the sub-macro map_grp_assoc2gene4covidsexgwas*/
design_width=475, 
design_height=475, 
barthickness=10, /*gene track bar thinkness*/
dotsize=4, 
dist2sep_genes=1000000,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(), /*where condition to filter input gwas_dsd*/

shift_text_yval=0.1, /*in terms of gene track labels, add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis; the default value is -0.2 to put gene lable under gene tracks;
                      Change it with the macro var pct4neg_y!*/
fig_fmt=png, /*output figure formats: svg, png, jpg, and others*/
pct4neg_y=1, /*the most often used value is 1;
              compacting the bed track y values by increasing the scatterplot scale, 
              which can reduce the bed trace spaces; It seems that two-fold increasement
              leads to better ticks for different tracks!
              Use value >1 will increase the gene tract, while value < 1 will reduce it!
              Note: when there are only 1 or 2 scatterplots, it is better to provide value = 0.5;
              Modify this parameter with the parameter shift_text_yval to adjust gene label!
              Typically, when there are more scatterplots, it is necessary to increase the value of pct4neg_y accordingly;
              If there are only <4 scatterplots, the value would be usually set as 1 or 2;
              */
adjval4header=-3, /*In terms of header of each subscatterplot, provide postive value to move up scatter group header by the input value*/
makedotheatmap=1,/*use colormap to draw dots in scatterplot instead of the discretemap;
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
SNPs2label_scatterplot_dots=&tgt_snps /*Add multiple SNP rsids to label dots within or at the top of scatterplot
Note: if this parameter is provided, it will replace the parameter var4label_scatterplot_dots!
*/
);
