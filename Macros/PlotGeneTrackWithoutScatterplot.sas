%macro PlotGeneTrackWithoutScatterplot(
gtf_dsd=FM.GTF_HG19,
/*demo for MAP3K19*/
chr=2,
minst=135023787,
maxend=137000000,
dist2genes=0,/*use it get SNPs located beyound the regions with the dist*/
dist2st_and_end=50000,/*to make the gene track to extend the regions beyound the gene st and end*/
design_width=1000,
design_height=400,
barthickness=15,
dotsize=6,
min_dist4genes_in_same_grps=0.4,
yaxis_offset4min=0.05, /*provide 0-1 value or auto to offset the min of the yaxis*/
yaxis_offset4max=0.05, /*provide 0-1 value or auto or to offset the max of the yaxis*/
xaxis_offset4min=0.02, /*provide 0-1 value or auto  to offset the min of the xaxis*/
xaxis_offset4max=0.02 /*provide 0-1 value or auto to offset the max of the xaxis*/
);

%GetGenesExons4LatticeGscatter(
gtf_dsd=&gtf_dsd,
chr=&chr,
min_st=&minst,
max_end=&maxend,
dist2genes=&dist2genes
);


*This input dsd bed_dsd;
*is for exonic bed regions, which should contains the following vars:;
*chr, st, end, and grp, and these varnames are fixed and used by the internal macro!;

*Make sure there is only one unique chr included in the gene_exon_bed_dsd when;
*the 1st data set bed_dsd is missing!;
*The typical input format of gene_exon_bed_dsd would be:;
*chr st end grp num_scattergrp;
*grp would be character, such as gene or exon;
*char_scattergrp would be y-axis values for these genes and it corresponding exons;

*Note: when bed_dsd is empty, it is still necessary to provide;
*the yval_var as y and scatter_grp_var as scattergrp;
*as the two vars are fixed by the macro GetGenesExons4LatticeGscatter;
*In addition, the mixed exons and genes will be determined for;
*the whole gene body covering a gene and its corresponding exons;
*You can further change the default parameter of the sub-macro to improve the figure;
*Lattice_gscatter_over_bed_track;

ods graphics on/reset=all;

%Multgscatter_with_gene_exons(
bed_dsd=,
yval_var=y,
scatter_grp_var=scattergrp,
lattice_subgrp_var=scattergrp,
gene_exon_bed_dsd=exons,
dist2st_and_end=&dist2st_and_end,
design_width=&design_width,
design_height=&design_height,
barthickness=&barthickness,
dotsize=&dotsize,
min_dist4genes_in_same_grps=&min_dist4genes_in_same_grps,
min_xaxis=&minst,/*These two parameters will restrict the min and max position for xaxis*/
max_xaxis=&maxend,
yaxis_offset4min=&yaxis_offset4min, /*provide 0-1 value or auto to offset the min of the yaxis*/
yaxis_offset4max=&yaxis_offset4max, /*provide 0-1 value or auto or to offset the max of the yaxis*/
xaxis_offset4min=&xaxis_offset4min, /*provide 0-1 value or auto  to offset the min of the xaxis*/
xaxis_offset4max=&xaxis_offset4max /*provide 0-1 value or auto to offset the max of the xaxis*/
);


%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;


*Note: the order of AssocPVars and ZscoreVars should be corresponded;
*The final figure tracts from bottom to up corresponding to the order of the above vars;
libname FM "%sysfunc(pathname(HOME))/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp";

%PlotGeneTrackWithoutScatterplot(
gtf_dsd=FM.GTF_HG19,
chr=2,
minst=135023787,
maxend=137000000,
dist2genes=0,
dist2st_and_end=50000,
design_width=1000,
design_height=400,
barthickness=15,
dotsize=6,
min_dist4genes_in_same_grps=0.4
);

*/
