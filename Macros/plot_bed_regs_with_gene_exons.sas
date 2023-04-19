%macro plot_bed_regs_with_gene_exons(
bed_dsd=,
gene_exon_bed_file=,
dist2st_and_end=50000,
design_width=1000,
design_height=200,
barthickness=20);

proc import datafile="&gene_exon_bed_file" dbms=tab out=exon_info replace;
getnames=no;
guessingrows=10000;
run;
/*proc print data=_last_(obs=10);run;*/

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
   select var1 as chr,var2 as st,var3 as end,var4 as grp,
          -1 as cnv
   from exon_info
   where var1="&_chr_" and (
         (var2<=&min_st and var3>=&min_st and var3<=&max_end ) or 
         (var2>=&min_st and var3<=&max_end) or 
         (var3>=&max_end and var2<=&max_end)
   );
   /*proc print data=exon&_chr_(obs=10);run;
   proc print data=bed&_chr_(obs=10);run;

   proc sql;
   create table _x_ as
   select *
   from bed&_chr_ 
   outer union corr
   select *
   from exon&_chr_;
   proc print;run; 
  
   *make the same grp have the same cnv value to draw regions of the same grp together;
   *Note: changing ngrp value leads to the separation or combination of different regions to be draw in a same line;
   %char_grp_to_num_grp(dsdin=_x_,grp_vars4sort=grp,descending_or_not=0,dsdout=_x1_,num_grp_output_name=ngrp);
 */
   %char_grp_to_num_grp(dsdin=bed&_chr_,grp_vars4sort=grp,descending_or_not=0,dsdout=bed&_chr_,num_grp_output_name=ngrp);
   %char_grp_to_num_grp(dsdin=exon&_chr_,grp_vars4sort=grp,descending_or_not=0,dsdout=exon&_chr_,num_grp_output_name=ngrp);
   *By asigning ngrp=-1, all gene tracks will be put under the refline y=0;
   data exon&_chr_;set exon&_chr_;ngrp=-1;run;
   data _x1_;set bed&_chr_ exon&_chr_;run;
   /*proc print;run;*/
			options nonotes;
   %bed_region_plot_by_grp(
    bed_dsd=_x1_,
    chr_var=chr,
    st_var=st,
    end_var=end,
    grp_var=grp,
    yval_var=ngrp,
    linethickness=&barthickness,
    track_width=&design_width,
    track_height=&design_height,
				dist2st_and_end=&dist2st_and_end
     );
				options notes;
%let ci=%eval(&ci+1);
%end;

%mend;

/*Demo:
*This macro is deprecated by a better macro: plot_scatter_with_gene_exons4dsd;
*The old macro used the old macro bed_region_plot_by_grp, which was replaced with;
*scatter_over_bed_track in the better macro;
*But this macro can be used to draw different CNVs with gene tracks under the ref line y=0;

%importallmacros;

data x0;
input chr $ st end cnv grp $;
cards;
chr1 207484943 207544185 1 a
chr1 207444185 207544185 2 b
;
run;

*options mprint mlogic symbolgen;
*exon_info.bed should be a file contains the following columns but no headers in order;
*chr,st,end,gene;
*Note: st and end are exonic positions;
*gtf=/research/rgs01/home/clusterHome/zcheng/NGS_lib/Linux_codes_SAM/VariantCalling/HTSeq4tSNE/Homo_sapiens.GRCh37.75.clean.characteric_chrs.gtf;
*get_gene_exon_bed_for_genes_from_gtf.sh $gtf >exon_info.bed;

%plot_bed_regs_with_gene_exons(
bed_dsd=x0,
gene_exon_bed_file=exon_info.bed,
dist2st_and_end=50000,
design_width=1000,
design_height=200,
barthickness=20);

*/
