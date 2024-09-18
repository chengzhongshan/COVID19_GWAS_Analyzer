%macro GetGenesExons4LatticeGscatter(
gtf_dsd=FM.GTF_HG19,
/*Need to use sas macro import gtf to save GTF_HG19;
the data format for the gtf_dsd is fixed with the following vars:
chr st end genesymbol type protein_coding
*/
chr=,
min_st=,
max_end=,
dist2genes=100000,
outdsd=exons
);

*Need to first select these genes and get their min_pos and max_pos;
*then use these regions to lookup with associaiton signals;
data exons(keep=_chr_ st end grp pi type);
length _chr_ $5.;
*Enlarge the length of grp, which may be truncated if too short!;
length grp $30.;
set &gtf_dsd;
pi=-1;
grp=genesymbol;
_chr_=cats("chr",put(chr,2.));
where chr=&chr and 
( (st between &minst and &maxend) or (end between &minst and &maxend) )and 
/* type="gene" and protein_coding=1; */
/*This does not work as expected, as some exons belonging to the same gene are colored differently*/
/*It is also very time-consuming*/
/* type in ("exon" "gene") and protein_coding=1; */
type in ("gene" "exon") and protein_coding=1 
and genesymbol not contains '.';
/*and genesymbol not contains 'ENSG';*/
run;

*Important to remove dup exons;
proc sort data=exons nodupkeys;by _all_;run;

*Count how many exons in the exons dsd;
*If there are more than 200, keep only gene and exclude all exons;
proc sql noprint;
select count(type) into: tot_exons
from exons
where type="exon";

%if &tot_exons > 1000 %then %do;
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
%if &tot_bed_regs > 2000 %then %do;
  %put Too many bed regions in your exon dsd;
		%put Only < 2000 bed regions can be fastly draw by the macro;
		%abort 255;
%end;

*Need to extend the min_st and max_end for better visualization in the final figure;
proc sql noprint;
select min(st)-1000, max(end)+1000 into :min_gpos,:max_gpos
from exons;
*Need to compare it with original input min_st and max_end;
%if &max_end>&max_gpos %then %let max_gpos=&max_end;
%if &min_st<&min_gpos %then %let min_gpos=&min_st;
%put The final chromosomal range for your query region is from &min_gpos to &max_gpos;

data exons(rename=(_chr_=chr pi=scattergrp));
set exons;
if _chr_="chr23" then _chr_="chrX";
y=-1;
run;

data &outdsd;
set exons;
run;

%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
proc datasets lib=FM;
run;

%let minst=119089629;
%let maxend=120320656;
%let chr=11;

%GetGenesExons4LatticeGscatter(
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
dist2genes=1000,
outdsd=exons
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

%Multgscatter_with_gene_exons(
bed_dsd=,
yval_var=y,
scatter_grp_var=scattergrp,
lattice_subgrp_var=scattergrp,
gene_exon_bed_dsd=exons,
dist2st_and_end=50000,
design_width=800,
design_height=400,
barthickness=15,
dotsize=6,
min_dist4genes_in_same_grps=0.4
);

*/


