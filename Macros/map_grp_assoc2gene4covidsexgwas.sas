%macro map_grp_assoc2gene4covidsexgwas(
gwas_dsd=FM.f_vs_m_mixedpop,
gtf_dsd=FM.GTF_HG19,/*Need to use sas macro import gtf to save GTF_HG19*/
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
gwas_pos_var=pos,
gwas_labels_in_order=gwas1_vs_gwas2 gwas1 gwas2 /*Provide gwas names matched with the numeric scatter_grp_var
Use _ to represent blank space in each name, and these _ will be changed back into blank space!*/
);
%if %ntokens(&gwas_labels_in_order)^=%ntokens(&AssocPVars) %then %do;
  %put Please ensure the gwas_labels_in_order has the same number of elements as that of AssocPVars;
  %put gwas_labels_in_order=;
  %put AssocPVars=;
  %abort 255;
%end;

%let min_st=%sysevalf(&min_st-&dist2genes);
%let max_end=%sysevalf(&max_end+&dist2genes);
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
( (st between &minst and &maxend) or (end between &minst and &maxend) )and 
/* type="gene" and protein_coding=1; */
/*This does not work as expected, as some exons belonging to the same gene are colored differently*/
/*It is also very time-consuming*/
/* type in ("exon" "gene") and protein_coding=1; */
type in ("gene" "exon") and protein_coding=1;
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

*Need to enlarge the grp length by asigning longer comman label for it;
*Filter input gwas_dsd with where condition to reduce the total number of markers;
proc sql;
create table signal_dsd as
select 
     %do i=1 %to &totP;
        %scan(&ZscoreVars,&i) > 0 as AssocGrp&i,
       -log10(%scan(&AssocPVars,&i)) as var4log10P&i,
     %end;
       &gwas_pos_var as st,&gwas_pos_var+1 as end,"GWAS_Assoc_Signal" as grp,
       cats("chr",put(chr,2.)) as _chr_
from &gwas_dsd	
%if "&where_cndtn_for_gwasdsd"^="" %then %do;
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
sc_labels_in_order=&gwas_labels_in_order /*Provide scatter names matched with the numeric scatter_grp_var*/
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


