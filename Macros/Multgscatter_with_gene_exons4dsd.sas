%macro Multgscatter_with_gene_exons4dsd(
bed_dsd=,
yval_var=,
scatter_grp_var=,
gene_exon_bed_dsd=,
dist2st_and_end=50000,
design_width=1000,
design_height=200,
barthickness=20,
makedotheatmap=0,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot*/

color_resp_var=,/*Use value of the var to draw colormap of dots in scatterplot
if empty, the default var would be the same as that of yval_var;*/

makeheatmapdotintooneline=0/*This will make all dots have the same yaxis value but have different colors 
based on its real value in the heatmap plot; To keep the original dot y axis value, assign 0 to the macro var
This would be handy when there are multiple subgrps represented by different y-axis values! By modifying
the y-axis values for these subgrps, the macro can plot them separately in each subtrack!
*/
);


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

data &gene_exon_bed_dsd;
set &gene_exon_bed_dsd;
&scatter_grp_var=-1;
run;

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
   from &bed_dsd;
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
   /*Only if you want to draw bed track instead of scatter plot for these no gene data points, you can increase the ratio*/         
   %let dist4scatterplot=%sysevalf((&max_end-&min_st)*0.0001,integer);
   *By asigning ngrp=-1, all gene tracks will be put under the refline y=0;
   data exon&_chr_;set exon&_chr_;&yval_var=-1;run;
   data _x1_;
   set bed&_chr_ exon&_chr_;
			*enlarge the dist between st and end, which will make the square visible in scatter plot; 
			st=st-&dist4scatterplot;
			if st<0 then st=0;
			end=end+&dist4scatterplot;
   run;
   /*proc print;run;*/
   *options nonotes;
   *old macro %bed_region_plot_by_grp, which is slow!;
   *Use the new macro by plotting scatter plot;

			*Fix a bug here;
			*Need to asign -1 for all groups of &yval_var;
			*such as &yval_var1,&yval_var2, and so on;
			*If not fix the bug, these missing groups will be ploted at the bottern of each subplot;
		 data _x1_;
			set _x1_;
			array Y{*} &yval_var.:;
			do yi=1 to dim(Y);
			   if Y{yi}=. then Y{yi}=-1;
			end;
			drop yi;
			run;

    %Lattice_gscatter_over_bed_track(
    bed_dsd=_x1_,
    chr_var=chr,
    st_var=st,
    end_var=end,
    grp_var=grp,
    scatter_grp_var=&scatter_grp_var,
    yval_var=&yval_var,
	yaxis_label=%str(-log10%(P%)),
    linethickness=&barthickness,
    track_width=&design_width,
    track_height=&design_height,
    dist2st_and_end=&dist2st_and_end,
	dotsize=8,
	makedotheatmap=&makedotheatmap,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot*/

color_resp_var=&color_resp_var,/*Use value of the var to draw colormap of dots in scatterplot
if empty, the default var would be the same as that of yval_var;*/

makeheatmapdotintooneline=&makeheatmapdotintooneline /*This will make all dots have the same yaxis value but have different colors 
based on its real value in the heatmap plot; To keep the original dot y axis value, assign 0 to the macro var
This would be handy when there are multiple subgrps represented by different y-axis values! By modifying
the y-axis values for these subgrps, the macro can plot them separately in each subtrack!
*/
     );
  
   *options notes;
%let ci=%eval(&ci+1);
%end;

%mend;

/*Demo:
*Note: this macro is with problem and can not plot correctly sometime;
*Need to debug it later;

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

data x0;
input chr $ st end cnv grp $ gscatter_grp;
*Make the st and end smaller and larger for visible in the final scatter plot;
cards;
chr1 207485943 207485944 10 a 1
chr1 207485953 207485954 20 a 1
chr1 207444185 207444186 2 b 2
chr1 207444195 207444196 40 b 2
;
run;
data exons;
input chr $ st end grp $ gscatter_grp;
cards;
chr1 207485943 207543185 X55 0
chr1 207434185 207534185 CD55 0
;
run;

*options mprint mlogic symbolgen;
*exon_info.bed should be a file contains the following columns but no headers in order;
*chr,st,end,gene;
*Note: st and end are exonic positions;
*gtf=/research/rgs01/home/clusterHome/zcheng/NGS_lib/Linux_codes_SAM/VariantCalling/HTSeq4tSNE/Homo_sapiens.GRCh37.75.clean.characteric_chrs.gtf;
*get_gene_exon_bed_for_genes_from_gtf.sh $gtf >exon_info.bed;

*Make sure the two datasets have 4 comman vars, including chr, st, end, and grp;
*Note: both the bed_dsd and gene_exon_bed_dsd should have char chromosomes;

%Multgscatter_with_gene_exons4dsd(
bed_dsd=x0,
yval_var=cnv,
scatter_grp_var=gscatter_grp,
gene_exon_bed_dsd=exons,
dist2st_and_end=5000,
design_width=1000,
design_height=600,
barthickness=20);

*/
