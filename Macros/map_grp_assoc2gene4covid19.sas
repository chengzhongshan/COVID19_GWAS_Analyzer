%macro map_grp_assoc2gene4covid19(
gwas_dsd=FM.f_vs_m_mixedpop,
gtf_dsd=FM.GTF_HG19,
chr=,
min_st=,
max_end=,
AssocP=pval,
AssocGrp=,
);

proc sql;
create table signal_dsd (where=(var4log10P>=1)) as
select &AssocGrp > 0 as &AssocGrp,
       pos as st,pos+1 as end,-log10(&AssocP) as var4log10P,
       "Signal" as grp,cats("chr",put(chr,2.)) as _chr_
from &gwas_dsd
where chr=&chr and 
(pos between &minst and &maxend);

data exons(keep=_chr_ st end grp);
length _chr_ $5.;
set &gtf_dsd;
grp=genesymbol;
_chr_=cats("chr",put(chr,2.));
where chr=&chr and 
( (st between &minst and &maxend) or (end between &minst and &maxend) )and 
type="gene" and protein_coding=1;
run;

data signal_dsd(rename=(_chr_=chr));
set signal_dsd;
if _chr_="chr23" then _chr_="chrX";
data exons(rename=(_chr_=chr));
set exons;
if _chr_="chr23" then _chr_="chrX";
run;

*Make sure the two datasets have 4 comman vars, including chr, st, end, and grp;
%gscatter_with_gene_exons4dsd(
bed_dsd=signal_dsd,
yval_var=var4log10P,
scatter_grp_var=&AssocGrp,
gene_exon_bed_dsd=exons,
dist2st_and_end=0,
design_width=800,
design_height=400,
barthickness=15);
%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
proc datasets lib=FM;
run;
proc contents data=FM.f_vs_m_mixedpop;
run;

%let minst=119489629;
%let maxend=120020656;
%let chr=11;
%map_grp_assoc2gene4covid19(
gwas_dsd=FM.f_vs_m_mixedpop,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
AssocP=pval,
AssocGrp=diff_zscore
);

%map_grp_assoc2gene4covid19(
gwas_dsd=FM.f_vs_m_mixedpop,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
AssocP=gwas1_p,
AssocGrp=gwas1_z
);

%map_grp_assoc2gene4covid19(
gwas_dsd=FM.f_vs_m_mixedpop,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
AssocP=gwas2_p,
AssocGrp=gwas2_z
);

*/


