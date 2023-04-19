%macro plot_bed_with_gene_exons4dsd(
bed_dsd=,
gene_exon_bed_dsd=,
dist2st_and_end=50000,
design_width=1000,
design_height=200,
barthickness=20);


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
   select chr,st,end,grp,
          -1 as cnv
   from &gene_exon_bed_dsd
   where chr="&_chr_" and (
         (st<=&min_st and end>=&min_st and end<=&max_end ) or 
         (st>=&min_st and end<=&max_end) or 
         (end>=&max_end and st<=&max_end)
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
%let ci=%eval(&ci+1);
%end;

%mend;

/*Demo:

%importallmacros;

data x0;
input chr $ st end cnv grp $;
cards;
chr1 207484943 207544185 1 a
chr1 207444185 207544185 2 b
;
run;
data exons;
input chr $ st end grp $;
cards;
chr1 207485943 207543185 CD55
chr1 207434185 207444185 CD55
;
run;

*options mprint mlogic symbolgen;
*exon_info.bed should be a file contains the following columns but no headers in order;
*chr,st,end,gene;
*Note: st and end are exonic positions;
*gtf=/research/rgs01/home/clusterHome/zcheng/NGS_lib/Linux_codes_SAM/VariantCalling/HTSeq4tSNE/Homo_sapiens.GRCh37.75.clean.characteric_chrs.gtf;
*get_gene_exon_bed_for_genes_from_gtf.sh $gtf >exon_info.bed;

*Make sure the two datasets have 4 comman vars, including chr, st, end, and grp;

%plot_bed_with_gene_exons4dsd(
bed_dsd=x0,
gene_exon_bed_dsd=exons,
dist2st_and_end=500000,
design_width=1000,
design_height=200,
barthickness=20);

*/
