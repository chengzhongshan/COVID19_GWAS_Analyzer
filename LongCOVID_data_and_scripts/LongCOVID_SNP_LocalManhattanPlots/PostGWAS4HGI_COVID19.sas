 *https://sesug.org/proceedings/sesug_2024_SAAG/PresentationSummaries/Papers/151_Final_PDF.pdf;
*options mprint mlogic symbolgen;
filename M url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
%include M;
Filename M clear;
%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0);
/* %macroparas(macrorgx=HGI); */

*Check the newly updated output GWAS data;
%ImportFileHeadersFromZIP( 
zip=E:\LongCOVID_HGI_GWAS\Multi_Long_GWAS_Integration\New_LongCOVID_GWAS_Publication_Materials2024\LongCOVID_Tables\THREEGWASs4HGICOVID19.gz,/*Only provide file with .gz, .zip, or common text file without comporession 
Note: it is necessary to have fullpath for the input file!*/ 
filename_rgx=., 
obs=max, 
sasdsdout=ThreeGWASs, 
deleteZIP=0, 
infile_command=%str(
firstobs=2 obs=max dlm=',' dsd truncover;
input 
rsid  :$15.
chr
pos
Ref :$1.
Alt :$1.
HGI_B1_beta
HGI_B2_beta
HGI_B1_P
HGI_B2_P
HGI_B1_se
HGI_B2_se
diff_B1_vs_B2_P
diff_B1_vs_B2_zscore
HGI_C2_P
HGI_C2_beta
HGI_C2_se
HGI_C2_AF;

/*firstobs=1 obs=2;*/
/*input;*/
/*info=_infile_;*/
), 
/*Better to use nrbquote to replace str and use unquote within the macro 
to get back the input infile_command;*/ 
extra_infile_macrovar_prefix=infile_cmd,/*To prevent the crash of sas when the length of the macro var infile_command is too long, 
it is better to assign different parts of infile commands into multiple global macro vars with similar prefix, such as infile_cmd; 
it is better to use bquote or nrbquote to excape each extra infile command!*/ 
num_infile_macro_vars=0,/*Provide positve number to work with the global macro var of extra_infile_macrovar_prefix*/ 
use_zcat=0, 
var4endlinenum=adj_endlinenum, /*make global var for the endline number but it is 
necessary to use syminputx in the infile_command to record the endline number; 
call symputx("&var4endlinenum",trim(left(put(_n_,8.)))); 
It is possible to assign other numeric value generated in the infile_command to 
this macro var for other purpose, because this global macro var will be accessible 
by other outsite macros! 
call symputx('adj_endlinenum',trim(left(put(rowtag,8.))));*/ 
global_var_prefix4vars2drop=drop_var,/*To handle the issue of trunction of macro var infile_command if there are too many variables to be dropped in the infile procedure; 
it is feasible to create global macro variables with the same prefix, such as drop_var, to exclude them*/ 
num_vars2drop=0 /*Provide postive number to work with the macro var global_var_prefix4vars2drop to resolve these variables to be excluded*/ 
);

data nonhosp_tophits(where=(HGI_B1_p<1e-5));
set ThreeGWASs;
where (HGI_B2_p>0.05 and HGI_B1_p<0.05 ) and HGI_C2_AF>0.01;
run;
%get_top_signal_within_dist(dsdin=nonhosp_tophits
                           ,grp_var=chr
                           ,signal_var=HGI_B1_p
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=1000000
                           ,dsdout=tops4nonhosp);

proc sql noprint;
select rsid into: nonhosp_snps separated by ' '
from tops4nonhosp;
%QueryHaploreg(/*Query Haploreg4 for each input SNP to get genes close to it!*/
rsids=&nonhosp_snps,
dsdout=results
);

proc sql; 
create table tops4nonhosp as 
select a.*,b.gene
from tops4nonhosp as a
left join
results as b
on a.rsid=b.rsid;

data D.nonhosp_tophits_new;
set tops4nonhosp;
run;

*For scenario 1 and 2;
data Tophits;
set ThreeGWASs;
*Note: gwas1 is for HGI-B1 and gwas2 is for HGI-B2;
*First one is for snps associated with both hospitalization and susceptibility;
*Second one is for snps more likely associated with hospitalization than mild covid;
where (
(HGI_C2_P<0.05 and HGI_B2_p<0.05 and HGI_B1_p<0.05 and diff_B1_vs_B2_P>0.05 and HGI_C2_beta*HGI_B2_beta>0 and HGI_C2_beta*HGI_B1_beta>0)
 or 
(HGI_C2_P<0.05 and HGI_B2_p<0.05 and HGI_B1_p>0.05 and diff_B1_vs_B2_P<0.05 and HGI_C2_beta*HGI_B2_beta>0) 
) and 
(HGI_C2_P<1e-7 or HGI_B2_p<1e-7 or HGI_B1_p<1e-7 or diff_B1_vs_B2_P<1e-7);
run;
proc print data=Tophits;
where rsid="rs3907022" or rsid="rs2496644";
run;

*Get top hits in each genomic windows;
data tops_small_p;
set tophits ;
small_p=min(of HGI_C2_P HGI_B1_p HGI_B2_p diff_B1_vs_B2_P);
run;

%get_top_signal_within_dist(dsdin=tops_small_p
                           ,grp_var=chr
                           ,signal_var=small_p
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=1000000
                           ,dsdout=tops);
data tops;
length grp $10.;
set tops;
if (HGI_B1_p>0.05 and diff_B1_vs_B2_P<0.05) then grp="Both";
else grp="Hosp";
run;
data tops(drop=grp);
length type $10.;
set tops;
type=grp;
run;
*lookup these SNPs with gene names and combine rsid and gene name as final y-axis tickets;
proc import datafile="E:\LongCOVID_HGI_GWAS\Multi_Long_GWAS_Integration\New_LongCOVID_GWAS_Publication_Materials2024\LongCOVID_Figures\top_snp2gene.csv"
dbms=csv out=snp2gene replace;
getnames=yes;guessingrows=max;
run;

proc sql;
create table tops as
select a.*,b.gene
from tops as a
left join 
snp2gene as b
on a.rsid=b.rsid;

data tops4nonhosp(drop=grp);
length type $10.;
set tops4nonhosp;
small_p=min(of HGI_C2_P HGI_B1_p HGI_B2_p diff_B1_vs_B2_P);
type="Nonhosp";
run;
data tops1;
set tops  tops4nonhosp;
run;


****************************************************************************************;
proc sort data=tops;by type HGI_B2_beta rsid;run;
*Draw forest plots for top hits;
%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=HGI_B1_beta, 
se_var=HGI_B1_se, 
sig_p_var=HGI_B1_p,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
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
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);

%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=HGI_B2_beta, 
se_var=HGI_B2_se, 
sig_p_var=HGI_B2_p,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_B2, 
figfmt=png,
figwidth=900,
figheight=1400, 
autolegend=0,
dotsize=6, 
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);

%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=HGI_C2_beta, 
se_var=HGI_C2_se, 
sig_p_var=HGI_C2_p,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_C2, 
figfmt=png,
figwidth=900,
figheight=1400, 
autolegend=0,
dotsize=6, 
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);

proc sql;
create table ThreeGWASs_Sub as
select a.*,b.grp,b.rsid as tag_snp
from tops as b
left join 
ThreeGWASs as a
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
proc sql;
create table hosp_snps as
select a.*,b.cls
from hosp_snps as a
left join
chr_colors as b
on a.chr=b.chr;
select cls into: hosp_chr_colors separated by ' '
from hosp_snps 
order by tag_snp;

%Manhattan4DiffGWASs(
dsdin=ThreeGWASs_Sub_nonhosp,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=tag_snp,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=HGI_B1_P,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=HGI_B2_P diff_B1_vs_B2_P HGI_C2_P, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=30, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
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
Use_scaled_pos=1,
sep_chr_grp=1
);

%Manhattan4DiffGWASs(
dsdin=ThreeGWASs_Sub_hosp,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=tag_snp,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=HGI_B1_P,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=HGI_B2_P diff_B1_vs_B2_P HGI_C2_P, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=30, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
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
Use_scaled_pos=1,
sep_chr_grp=1
);


proc sql noprint;
select unique(rsid) into: nonhosp_snps	 separated by ' '
from tops
where  grp="Nonhosp";
select unique(rsid) into: hosp_snps	 separated by ' '
from tops
where  grp="Hosp";


*Note: draw local manhattan for each GWAS by updating the Yaxis_Col_Name, i.e., p value variable from each GWAS;
*p, HGI_B1_p, HGI_B2_p, pval;
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=ThreeGWASs_Sub_nonhosp,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=HGI_C2_P,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=&nonhosp_snps,
design_width=1200,
design_height=300
);

%put &hosp_snps;
*Only focus on limited number of SNPs for making local mahattan plots;
%select_element_range_from_list(list=&hosp_snps,st=1,end=15,sublist=hosp_snps_sub,sep=\s);
%select_element_range_from_list(list=&hosp_snps,st=16,end=,sublist=hosp_snps_sub,sep=\s);
%put &hosp_snps_sub;
/*%debug_macro;*/
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=ThreeGWASs_Sub_hosp,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=HGI_B2_p,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=&hosp_snps_sub,
design_width=1200,
design_height=300
);

*Also make effect size dot plots;
data tgt;
set ThreeGWASs_Sub_nonhosp;
/*where chr=17;*/
where tag_snp="rs12976386";
run;
proc sql;
select min(pos) as minpos,max(pos) as maxpos
from tgt;

%Manhattan4DiffGWASs(
dsdin=tgt,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=chr,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=HGI_B1_P,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=HGI_B2_P diff_B1_vs_B2_P  HGI_C2_P, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
dotsize=1,/*The dot size for scatter plots*/
_logP_topval=10, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
fig_width=1200,
fig_height=1000,
fontsize=2,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three /*a prefix used to label the output figure*/
);

libname D "%sysfunc(pathname(HOME))";
*It is only needed to run once for importing the hg19 GTF file;
%let gtf_gz_url=https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gtf.gz;
/* %debug_macro; */
%get_genecode_gtf_data(
gtf_gz_url=&gtf_gz_url,
outdsd=D.GTF_HG19
);


%SNP_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro*/
gwas_dsd=ThreeGWASs_Sub,
chr_var=chr,
AssocPVars=HGI_B2_p HGI_B1_p diff_B1_vs_B2_P  HGI_C2_P,
SNP_IDs=rs3907022,
/*if providing chr:pos or chr:st:end, it will query by pos;
Please also enlarge the dist2snp to extract the whole gene body and its exons,
altought the final plots will be only restricted by the input st and end positions!*/
dist2snp=200000,
/*in bp; left or right size distant to each target SNP for the Manhattan plot*/
SNP_Var=rsid,
Pos_Var=pos,
gtf_dsd=D.GTF_HG19,
ZscoreVars=HGI_B2_beta HGI_B1_beta diff_B1_vs_B2_zscore HGI_C2_beta,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
gwas_labels_in_order=HGI_B2 HGI_B1 HGI_B1_vs_B2 HGI_C2,/*If providing _ for labeling each GWAS, 
the _ will be replaced with empty string, which is useful when wanting to remove gwas label 
if only one scatterplot or the label for a gwas containing spaces;
The list will be used to label scatterplots 
by the sub-macro map_grp_assoc2gene4covidsexgwas*/
design_width=800, 
design_height=900, 
barthickness=10, /*gene track bar thinkness*/
dotsize=5, 
dist2sep_genes=100000,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(), /*where condition to filter input gwas_dsd*/

shift_text_yval=0.1, /*in terms of gene track labels, add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis; the default value is -0.2 to put gene lable under gene tracks;
                      Change it with the macro var pct4neg_y!*/
fig_fmt=png, /*output figure formats: svg, png, jpg, and others*/
pct4neg_y=3, /*the most often used value is 1;
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
SNPs2label_scatterplot_dots=rs3907022 /*Add multiple SNP rsids to label dots within or at the top of scatterplot
Note: if this parameter is provided, it will replace the parameter var4label_scatterplot_dots!
*/
);
