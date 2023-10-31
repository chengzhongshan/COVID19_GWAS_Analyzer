%macro Multgscatter_with_gene_exons(
bed_dsd=,/*This input dsd should contain association signals, but not 
for gene bed regions; the name of the var should not be misunderstood!
It should contain the arbitrary vars: chr, st, and end
If the bed_dsd is missing, the macro will use the min and max position from
the gene_exon_bed_dsd as a fake data set to draw track without the scatterplot;
The typical input format of bed_dsd would be:
chr st end grp num_scattergrp num_lattice_scattergrp
the var grp should be character;
*/
yval_var=,
scatter_grp_var=,
lattice_subgrp_var=,
gene_exon_bed_dsd=,
/*
This input dsd is for exonic bed regions, which should contains the following vars:
chr, st, end, and grp, and these varnames are fixed and used by the internal macro!
Make sure there is only one unique chr included in the gene_exon_bed_dsd when the 1st data set bed_dsd is missing!
The typical input format of gene_exon_bed_dsd would be:
chr st end grp num_scattergrp
grp would be character, such as gene or exon
char_scattergrp would be y-axis values for these genes and it corresponding exons;
*/
dist2st_and_end=50000,
design_width=1000,
design_height=200,
barthickness=20,
dotsize=6,
min_dist4genes_in_same_grps=0.3, 
/*this will ensure these genes close to each other to 
be separated in the final gene track; 
(1) give 0 to plot ALL genes in the same line;
(2) give value between 0 and 1 to separate genes based on the pct distance to the whole region;
(3) give value > 1 to use absolute distance to separate genes into different groups;
Customize this for different gene exon track!*/
sc_labels_in_order= ,/*Provide scatter names matched with the numeric scatter_grp_var
Use _ to represent blank space in each name, and these _ will be changed back into blank space!*/

/*Note: More parameters included in the sub-macro Lattice_gscatter_over_bed_track 
can be modified to obtain better figures; please just find the sub-macro and
update the default setting for specific parameters to improve the final figure
*/
min_xaxis=,/*These two parameters will restrict the min and max position for xaxis*/
max_xaxis=,
yaxis_offset4min=0.05, /*provide 0-1 value or auto to offset the min of the yaxis*/
yaxis_offset4max=0.05, /*provide 0-1 value or auto or to offset the max of the yaxis*/
xaxis_offset4min=0.02, /*provide 0-1 value or auto  to offset the min of the xaxis*/
xaxis_offset4max=0.02, /*provide 0-1 value or auto to offset the max of the xaxis*/

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
var4label_scatterplot_dots= /*Make sure the variable name is not grp, which is a fixed var used by the macro for other purpose;
Whenever  makeheatmapdotintooneline=1 or 0, it is possible to use values of the var4label_scatterplot_dots to
label specific scatterplot dots based on the customization of the variable predifined by users for the input data set; 
default is empty; provide a variable that include non-empty strings for specific dots in the 
scatterplots;*/
);

%let missingscatterdsd=0;
%if %length(&bed_dsd)=0 %then %do;
 %put Going to use the ene_exon_bed_dsd to make fake scatterplot dsd;
 %let bed_dsd=fake_bed_dsd;
 proc sql;
 create table &bed_dsd as
 select *
 from &gene_exon_bed_dsd
 group by chr
 having st=min(st) or end=max(end);

 %let missingscatterdsd=1;
 *Also need to create these variables;
 %let yval_var=yval_var;
 %let lattice_subgrp_var=lattice_subgrp_var;
 
 data &bed_dsd;
 set &bed_dsd;
 *Assign yval_var with value 1, these values will be excluded latter by the sub-macro lattice_gscatter;
 *with the parameter NotDrawScatterPlot=&missingscatterdsd;
 &yval_var=1;
 *This variables should be the same types as that from gene_exon_bed_dsd;
 &scatter_grp_var=1;
 *This arbitary group var;
 grp="sc";
 *This variable should be numeric;
 &lattice_subgrp_var=1;
 run;
 *Only keep these common vars, other vars may be conficted with newly generated vars;
 data &gene_exon_bed_dsd;
 set &gene_exon_bed_dsd;
 keep chr st end grp;
 *Need to add the following var and asign negative value;
 *For gene and exon, this var need to be negative;
 &scatter_grp_var=-1;
 run;
%end;


/*proc print data=_last_(obs=10);run;*/

*Note: both the bed_dsd and gene_exon_bed_dsd should have char chromosomes;

/*
%chr_format_exchanger(
dsdin=_last_,
char2num=1,
chr_var=chr,
dsdout=a1);
*/

/*%chr_format_exchanger(
dsdin=x0,
char2num=0,
chr_var=chr,
dsdout=x1);
*/

/*data &gene_exon_bed_dsd;*/
/*set &gene_exon_bed_dsd;*/
/*&scatter_grp_var=-1;*/
/*run;*/

proc sql noprint;
select unique(chr) into: chrs separated by " "
from &bed_dsd;
%put These chromosomes are included in the bed dsd &bed_dsd: &chrs;

%let ci=1;

%do %while (%scan(&chrs,&ci) ne );
   %let _chr_=%scan(&chrs,&ci);
   %put running analysis for chromosome &_chr_;

   proc sql noprint;
   create table bed&_chr_ as
   select * 
   from &bed_dsd
   where chr="&_chr_";
   
   select min(st)-&dist2st_and_end,max(end)+&dist2st_and_end into: min_st,:max_end
   from bed&_chr_;
      
   create table exon&_chr_ as
   select chr,st,end,grp,
          -1 as &yval_var
   from &gene_exon_bed_dsd
   where chr="&_chr_" and (
         (st<=&min_st and end>=&min_st and end<=&max_end ) or 
         (st>=&min_st and end<=&max_end) or 
         (end>=&max_end and st<=&max_end)
   );

   %delete_empty_dsd(dsd_in=work.exon&_chr_);
   %if %eval(%sysfunc(exist(work.exon&_chr_))^=1) %then %do;
     %put No scatter data positions overlapped with exon regions, please enlarge the searching distance!;
       %abort 255;
   %end;

   /*Only if you want to draw bed track instead of scatter plot for these no gene data points, you can increase the ratio*/         
   %let dist4scatterplot=%sysevalf((&max_end-&min_st)*0.0001,integer);

   *By asigning ngrp=-1, all gene tracks will be put under the refline y=0;
			*This will asign the negative value -1 to gene grps and draw them together on a single line;
   /*data exon&_chr_;set exon&_chr_;&yval_var=-1;run;*/

			*This will asign different negative values to gene grps and draw them separately;
			proc sort data=exon&_chr_;by grp;run;

/* 			data exon&_chr_; */
/* 			retain &yval_var 0; */
/* 			*Make sure to drop the &yval_var from the dsd, otherwise, the retain and if condition will not work; */
/* 			set exon&_chr_ (drop=&yval_var); */
/* 			*Draw all genes into separated lines, but these exons may be draw into single lines, too?; */
/* 			*if first.grp then &yval_var=&yval_var-1; */
/*             *Draw all genes in a single line; */
/*             if first.grp then &yval_var=-1; */
/* 			output; */
/* 			by grp; */
/* 			run; */
*Use a macro to asign yval_var by separating genes too close to each other;
*reg_type and focused_reg_type4grouping can be omitted if wanting to use the longest region as gene;
   %adj_grpnum4close_gene_bed_regs(
   gene_bed_dsd=exon&_chr_,
   st_var=st,
   end_var=end,
   reg_type=,
   focused_reg_type4grouping=,
   gene_grp=grp,
   gene_dist_thrhd=&min_dist4genes_in_same_grps,
   dsdout=exon&_chr_,
   outnumgrp=_numgrp_
   );
   *Asign negative value to &yval_var;
   *Note: the above macro can not output the var outnumgrp with the same name of &yval_var in the table exon&_chr_;
   data exon&_chr_(drop=_numgrp_);
   set exon&_chr_;
   &yval_var=-1*_numgrp_;
   run;
			
   data _x1_;
   set bed&_chr_ exon&_chr_;
			*enlarge the dist between st and end, which will make the square visible in scatter plot; 
			st=st-&dist4scatterplot;
			if st<0 then st=0;
			end=end+&dist4scatterplot;
   run;
			

			*Fix a bug here;
			*Need to asign -1 for all groups of &yval_var;
			*such as &yval_var1,&yval_var2, and so on;
			*If not fix the bug, these missing groups will be ploted at the bottern of each subplot;
		 data _x1_;
			set _x1_;
			*No need to process these data when missingscatterdsd is true;
			%if &missingscatterdsd=0 %then %do;
			array Y{*} &yval_var.:;
			do yi=1 to dim(Y);
			   if Y{yi}=. then Y{yi}=-1;
			end;
			drop yi;
			%end;
			if &scatter_grp_var=. then &scatter_grp_var=-1;
			run;
	
   /*proc print;run;*/
   *options nonotes;
   *old macro %bed_region_plot_by_grp, which is slow!;
   *Use the new macro by plotting scatter plot;
   *There are many more parameters with default settings are not;
   *listed out for the following macro, and it is easy to the change;
   *them for better visualization in the final figure;
    %let yaxislabel=%str(-log10%(P%));
    *remove yaxis label when setting of NotDrawScatterPlot is true;
    %if &missingscatterdsd=1 %then %let yaxislabel=;

    %Lattice_gscatter_over_bed_track(
    bed_dsd=_x1_,
    chr_var=chr,
    st_var=st,
    end_var=end,
    grp_var=grp,
    scatter_grp_var=&scatter_grp_var,
    lattice_subgrp_var=&lattice_subgrp_var,
    yval_var=&yval_var,
    yaxis_label=&yaxislabel,
    linethickness=&barthickness,
    track_width=&design_width,
    track_height=&design_height,
    dist2st_and_end=&dist2st_and_end,
    dotsize=&dotsize,
    ordered_sc_grpnames=&sc_labels_in_order,
    NotDrawScatterplot=&missingscatterdsd,
    xaxis_viewmin=&min_xaxis,/*arbitrary xaxis min value to show the figure, and it requires to work with thresholdmin=0*/
    xaxis_viewmax=&max_xaxis,/*arbitrary xaxis max vale to show the figure, and it requires to go along with thresholdmax=0*/
    yaxis_offset4min=&yaxis_offset4min, /*provide 0-1 value or auto to offset the min of the yaxis*/
    yaxis_offset4max=&yaxis_offset4max, /*provide 0-1 value or auto or to offset the max of the yaxis*/
    xaxis_offset4min=&xaxis_offset4min, /*provide 0-1 value or auto  to offset the min of the xaxis*/
    xaxis_offset4max=&xaxis_offset4max, /*provide 0-1 value or auto to offset the max of the xaxis*/

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
  
   *options notes;
%let ci=%eval(&ci+1);
%end;

%mend;

/*Demo:
*Simulated data;
****************************************************************************;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

data x0;
input chr $ st end cnv grp $ gscatter_grp lattice_subgrp;
*Make the st and end smaller and larger for visible in the final scatter plot;
cards;
chr1 207485943 207485944 10.4 a 1 0
chr1 207486953 207489954 20.5 a 1 0
chr1 207444185 207444186 2.8 b 2 1
chr1 207444195 207444196 40.1 b 2 1
;
run;
proc print;run;

data exons;
input chr $ st end grp $ gscatter_grp;
cards;
chr1 207405943 207685943 X55 -1
chr1 207495943 207520000 X55 -1
chr1 207530943 207585943 X55 -1
chr1 207404185 207634185 CD55 -2
chr1 207424185 207504185 CD55 -2
chr1 207514185 207534185 CD55 -2
chr1 207494185 207599185 CD56 -3
;
run;

proc print;run;


options mprint mlogic symbolgen;
*exon_info.bed should be a file contains the following columns but no headers in order;
*chr,st,end,gene;
*Note: st and end are exonic positions;
*gtf=/research/rgs01/home/clusterHome/zcheng/NGS_lib/Linux_codes_SAM/VariantCalling/HTSeq4tSNE/Homo_sapiens.GRCh37.75.clean.characteric_chrs.gtf;
*get_gene_exon_bed_for_genes_from_gtf.sh $gtf >exon_info.bed;
*Make sure the two datasets have 4 comman vars, including chr, st, end, and grp;
*Note: for genes, the grp will be used to asign negative values for different genes;
*      and draw genes into different lines;
*Note: both the bed_dsd and gene_exon_bed_dsd should have char chromosomes;

*Here the bed_dsd of association signals is omitted to only draw gene track;

%Multgscatter_with_gene_exons(
bed_dsd=,
yval_var=cnv,
scatter_grp_var=gscatter_grp,
lattice_subgrp_var=lattice_subgrp,
gene_exon_bed_dsd=exons,
dist2st_and_end=5000,
design_width=600,
design_height=600,
barthickness=7,
min_dist4genes_in_same_grps=0.3
);


****************************************************************************;
*Demo for HGI_B1 and HGI_B2 gwas data;
%let minst=135023787;
%let maxend=136523787;
%let chr=2;

*Note: the order of AssocPVars and ZscoreVars should be corresponded;
*The final figure tracts from bottom to up corresponding to the order of the above vars;
libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
libname D '/home/cheng.zhong.shan/data';
ods graphics on /reset=all;
options mprint mlogic symbolgen;
%map_grp_assoc2gene4covidsexgwas(
gwas_dsd=D.HGI_B1_vs_B2,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
dist2genes=0,
AssocPVars=pval gwas1_p gwas2_p,
ZscoreVars=diff_zscore gwas1_z gwas2_z
);


****************************************************************************;
*Demo for regeneron gwas data;
x cd "J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\MAP3K19_Manuscript\Figures_Tables\regeneron_GWAS4MAP3K19_and_others";
proc import datafile="MAP3K19_and_close_genes_covid19_sigs.csv" 
dbms=csv out=x replace;
getnames=yes;guessingrows=100000;
run;
data a(keep=chr st end logpval OR scgrp ltgrp grp where=(ltgrp contains 'not_hospitalized_vs'));
length grp $500.;
set x;
chr=scan(variant,1,":");
st=scan(variant,2,":")+0;
end=st+1;
ltgrp=trim(left(phenotype))||"_"||trim(left(study))||"_"||trim(left(Ancestry));
ltgrp=prxchange('s/covid-19 //i',-1,ltgrp);
*Need to remove spaces for the lattice_gscatter_over_bed_trace macro;
ltgrp=prxchange('s/ +/_/',-1,ltgrp);
logpval=-log10(p_value);
grp="signal";
OR=scan(Effect__OR___CI_,2,' ')+0;
if scan(Effect__OR___CI_,1,' ')^="UP" then OR=OR*-1;
if OR>0 then scgrp=1;
else scgrp=0;
run;
proc sort data=a;by ltgrp;run;
data a;
retain gscatter_grp 0;
set a;
if first.ltgrp then gscatter_grp=gscatter_grp+1;
by ltgrp;
if chr="2";
run;

data exons;
input chr $ st end grp $ gscatter_grp;
cards;
2 134751052 135580621 fgene -1
;
run;

*options mprint mlogic symbolgen;
*exon_info.bed should be a file contains the following columns but no headers in order;
*chr,st,end,gene;
*Note: st and end are exonic positions;
*gtf=/research/rgs01/home/clusterHome/zcheng/NGS_lib/Linux_codes_SAM/VariantCalling/HTSeq4tSNE/Homo_sapiens.GRCh37.75.clean.characteric_chrs.gtf;
*get_gene_exon_bed_for_genes_from_gtf.sh $gtf >exon_info.bed;

*Make sure the two datasets have 4 comman vars, including chr, st, end, and grp;
*Note: for genes, the grp will be used to asign negative values for different genes;
*      and draw genes into different lines;
*Note: both the bed_dsd and gene_exon_bed_dsd should have char chromosomes;

%Multgscatter_with_gene_exons(
bed_dsd=a,
yval_var=logpval,
scatter_grp_var=gscatter_grp,
lattice_subgrp_var=scgrp,
gene_exon_bed_dsd=exons,
dist2st_and_end=500000,
design_width=1000,
design_height=2000,
barthickness=20,
min_dist4genes_in_same_grps=0.1
);

*print the gwas tract names from down to up;
proc sql;
select unique(ltgrp)
from a 
order by gscatter_grp;


*/
