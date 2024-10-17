%macro map_grp_assoc2gene4covidsexgwas(
gwas_dsd=FM.f_vs_m_mixedpop,/*Requires to have the arbitary var 
chr in the input gwas dsd*/
gtf_dsd=FM.GTF_HG19,/*Need to use sas macro import gtf to save GTF_HG19;
these vars are arbitrary, such as chr, st, end, protein_coding (1 or 0)
and type of bed region (gene or exon);*/
chr=,
min_st=,
max_end=,
dist2genes=100000,
AssocPVars=pval gwas1_p gwas2_p,
ZscoreVars=diff_zscore gwas1_z gwas2_z,
design_width=800,/*Width*height=800*800 would be the best for publication*/
design_height=800,
barthickness=8,
dotsize=6,
dist2sep_genes=0.3, /*
this will ensure these genes close to each other to 
be separated in the final gene track; 
(1) give 0 to plot ALL genes in the same line;
(2) give value between 0 and 1 to separate genes based on the pct distance to the whole region;
(3) give value > 1 to use absolute distance to separate genes into different groups;
Customize this for different gene exon track!
*/
where_cndtn_for_gwasdsd=%str() /*add filters to the input gwas_dsd; such as pval < 0.05 or gwas1_p < 0.05 or gwas2_p < 0.05*/,

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

gwas_pos_var=pos,
gwas_labels_in_order=gwas1_vs_gwas2 gwas1 gwas2, /*Provide gwas names matched with the numeric scatter_grp_var
Use _ to represent blank space in each name, and these _ will be changed back into blank space!*/
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
var4label_scatterplot_dots=, /*Make sure the variable name is not grp, which is a fixed var used by the macro for other purpose;
Whenever  makeheatmapdotintooneline=1 or 0, it is possible to use values of the var4label_scatterplot_dots to
label specific scatterplot dots based on the customization of the variable predifined by users for the input data set; 
default is empty; provide a variable that include non-empty strings for specific dots in the 
scatterplots;*/
yoffset4max_drawmarkersontop=0.15 /*If draw scatterplot marker labels on the top of track, 
 this fixed value will be used instead of yaxis_offset4max!*/
);
%if %ntokens(&gwas_labels_in_order)^=%ntokens(&AssocPVars) %then %do;
  %put Please ensure the gwas_labels_in_order has the same number of elements as that of AssocPVars;
  %put gwas_labels_in_order=;
  %put AssocPVars=;
  %abort 255;
%end;

%let orig_minst=&min_st;
%let orig_maxend=&max_end;

%let min_st=%sysevalf(&min_st-&dist2genes);
%let max_end=%sysevalf(&max_end+&dist2genes);

*if the dist between min_st and max_end, the range may not be;
*able to cover the gene body, resulting in failure of drawing gene body and exons;
%if %sysevalf(&max_end - &min_st)<1e8 %then %do;
 %put Extend to the st and end position to cover gene bodies and exons;
 %let min_st=%sysevalf(&min_st - 50000000);
 %let max_end=%sysevalf(&max_end + 50000000);
%end;


%let totP=%sysfunc(countw(&AssocPVars));
%if &totP ne %sysfunc(countw(&ZscoreVars)) %then %do;
    %put Please make sure the two macro vars have the same number of parameters:;
    %put Your AssocPVars: &AssocPVars;
    %put Your ZscoreVars: &ZscoreVars;
    %abort 255;
%end;

*Need to first select these genes and get their min_pos and max_pos;
*then use these regions to lookup with associaiton signals;
data exons(keep=_chr_ st end grp pi type);
length _chr_ $5.;
*Enlarge the length of grp, which may be truncated if too short!;
length grp $30.;
set &gtf_dsd;
pi=0;
grp=genesymbol;
_chr_=cats("chr",put(chr,2.));
where chr=&chr and 
( (st between &min_st and &max_end) or (end between &min_st and &max_end) )
and 
/* type="gene" and protein_coding=1; */
/*This does not work as expected, as some exons belonging to the same gene are colored differently*/
/*It is also very time-consuming*/
/* type in ("exon" "gene") and protein_coding=1; */
type in ("gene" "exon") and protein_coding=1 and genesymbol not contains '.';
/*and genesymbol not contains 'ENSG';*/
run;
/* %abort 255; */

*Important to remove dup exons;
proc sort data=exons nodupkeys;by _all_;run;

*Count how many exons in the exons dsd;
*If there are more than 1000, keep only gene and exclude all exons;
proc sql noprint;
select count(type) into: tot_exons
from exons
where type="exon";
%put There are &tot_exons unique exons!;
%if &tot_exons > 20000 %then %do;
%put There are too many exons in the input dataset, with n=%left(&tot_exons)!;
%put The macro will exclude these exons;
/*%abort 255;*/
data exons;
set exons;
where type^="exon";
run;
%end;


*Need to drop the var type;
data exons;
set exons(drop=type);
run;
proc sql noprint;
select count(*) into: tot_bed_regs
from exons;
%if &tot_bed_regs > 20000 %then %do;
  %put Too many bed regions in your exon dsd;
		%put Only < 20000 bed regions can be fastly draw by the macro;
		%abort 255;
%end;

*Need to extend the min_st and max_end for better visualization in the final figure;
proc sql noprint;
select min(st)-1000-&dist2genes, max(end)+1000+&dist2genes 
into :min_gpos,:max_gpos
from exons;
*Need to compare it with original input min_st and max_end;
%if &max_end>&max_gpos %then %let max_gpos=&max_end;
%if &min_st<&min_gpos %then %let min_gpos=&min_st;
%put The final chromosomal range for your query region is from &min_gpos to &max_gpos;
%put However, we will restrict the x-axis to the original min and max genomic position in the final figure;
*Need to enlarge the grp length by asigning longer comman label for it;
*Filter input gwas_dsd with where condition to reduce the total number of markers;
proc sql;
create table signal_dsd as
select 
     %if %length(&color_resp_var)>0 %then %do;
       &color_resp_var,
     %end;
     %if %length(&var4label_scatterplot_dots)>0 %then %do;
       &var4label_scatterplot_dots,
     %end;
     
     %do i=1 %to &totP;
        %scan(&ZscoreVars,&i) > 0 as AssocGrp&i,
       -log10(%scan(&AssocPVars,&i)) as var4log10P&i,
     %end;
       &gwas_pos_var as st,&gwas_pos_var+1 as end,"GWAS_Assoc_Signal" as grp,
       cats("chr",put(chr,2.)) as _chr_
from &gwas_dsd	
%if %length(&where_cndtn_for_gwasdsd)^=0 %then %do;
(where=(&where_cndtn_for_gwasdsd))
%end;
where chr=&chr and 
(&gwas_pos_var between &min_gpos and &max_gpos);
/* The region will be different from the (pos between &minst and &maxend); */


data signal_dsd(where=(var4log10P>0));
*The final output would be necessary with p<0.05;
set signal_dsd;
array X{*} var4log10P1-var4log10P&totP;
array Z{*} AssocGrp1-AssocGrp&totP;
do pi=1 to dim(X);
   var4log10P=X{pi};
   AssocGrp=Z{pi};
   output;
end;
run;


data signal_dsd(rename=(_chr_=chr));
set signal_dsd;
if _chr_="chr23" then _chr_="chrX";
data exons(rename=(_chr_=chr));
set exons;
if _chr_="chr23" then _chr_="chrX";
run;
/*%abort 255;*/
*Make sure the two datasets have 4 comman vars, including chr, st, end, and grp;
*Need to ensure the dist2st_and_end as 0 to make the final scatterplot and gene track matching perfectly.;
%Multgscatter_with_gene_exons(
bed_dsd=signal_dsd,
yval_var=var4log10P,
scatter_grp_var=pi,
lattice_subgrp_var=AssocGrp,
gene_exon_bed_dsd=exons,/*Too many exons will slow down the macro dramatically*/
dist2st_and_end=0,
design_width=&design_width,
design_height=&design_height,
barthickness=&barthickness,
dotsize=&dotsize,
min_dist4genes_in_same_grps=&dist2sep_genes, /*
this will ensure these genes close to each other to 
be separated in the final gene track; 
(1) give 0 to plot ALL genes in the same line;
(2) give value between 0 and 1 to separate genes based on the pct distance to the whole region;
(3) give value > 1 to use absolute distance to separate genes into different groups;
Customize this for different gene exon track!*/
sc_labels_in_order=&gwas_labels_in_order, /*Provide scatter names matched with the numeric scatter_grp_var*/
min_xaxis=&orig_minst,
max_xaxis=&orig_maxend,
yoffset4max_drawmarkersontop=&yoffset4max_drawmarkersontop,/*If draw scatterplot marker labels on the top of track, 
this fixed value will be used instead of yaxis_offset4max!*/
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
%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
proc datasets lib=FM;
run;
proc contents data=FM.f_vs_m_gwas;
run;

%let minst=119089629;
%let maxend=120320656;
%let chr=11;
%map_grp_assoc2gene4covidsexgwas(
gwas_dsd=FM.f_vs_m_gwas,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
dist2genes=1000,
AssocPVars=pval gwas1_p gwas2_p,
ZscoreVars=diff_zscore gwas1_z gwas2_z,
design_width=800,
design_height=800,
barthickness=10,
dotsize=8,
dist2sep_genes=0.2,
where_cndtn_for_gwasdsd=%str( pval < 0.05 ),
gwas_pos_var=pos
);

*For debugging!;
proc export data=signal_dsd outfile='signal_dsd.txt' dbms=tab replace;
run;
proc export data=exons outfile='exons.txt' dbms=tab replace;
run;

*/


