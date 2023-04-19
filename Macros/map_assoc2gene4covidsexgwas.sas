%macro map_assoc2gene4covidsexgwas(
gwas_dsd=FM.f_vs_m_mixedpop,
gtf_dsd=FM.GTF_HG19,
chr=,
min_st=,
max_end=,
AssocPVars=pval gwas1_p gwas2_p,
ZscoreVars=diff_zscore gwas1_z gwas2_z
);
%let totP=%sysfunc(countw(&AssocPVars));
%if &totP ne %sysfunc(countw(&ZscoreVars)) %then %do;
    %put Please make sure the two macro vars have the same number of parameters:;
    %put Your AssocPVars: &AssocPVars;
    %put Your ZscoreVars: &ZscoreVars;
    %abort 255;
%end;
proc sql;
create table signal_dsd as
select pos as st,pos+1 as end,
     %do i=1 %to &totP;
       -log10(%scan(&AssocPVars,&i)) as var4log10P&i,
       %scan(&ZscoreVars,&i) > 0 as direction&i,
     %end;
       cats("chr",put(chr,2.)) as _chr_
from &gwas_dsd
where chr=&chr and 
(pos between &minst and &maxend);

*Make long format data;
*Need to have grp, which is used by the macro;
*%Multgscatter_with_gene_exons4dsd;
data signal_dsd(where=(var4log10P>=1));
set signal_dsd;
array X{*} var4log10P1-var4log10P&totP;
array Z{*} direction1-direction&totP;
do pi=1 to dim(X);
   var4log10P=X{pi};
   *grp=Z{pi};
   grp='Signal';
   output;
end;
run;
*Note: pi is in according to the order of input P vars;

data exons(keep=_chr_ st end grp pi);
length _chr_ $5.;
set &gtf_dsd;
grp=genesymbol;
pi=0;
*Make sure to asign var4log10P with value -1 for gene groups;
var4log10P=-1;
_chr_=cats("chr",put(chr,2.));
where chr=&chr and 
( (st between &minst and &maxend) or (end between &minst and &maxend) )and 
type="gene" and protein_coding=1;
/*this will slow down the script dramatically*/
/* type="exon" and protein_coding=1; */
run;

data signal_dsd(rename=(_chr_=chr));
set signal_dsd;
if _chr_="chr23" then _chr_="chrX";
data exons(rename=(_chr_=chr));
set exons;
if _chr_="chr23" then _chr_="chrX";
run;

*Make sure the two datasets have 4 comman vars, including chr, st, end, and grp;
%Multgscatter_with_gene_exons4dsd(
bed_dsd=signal_dsd,
yval_var=var4log10P,
scatter_grp_var=pi,
gene_exon_bed_dsd=exons,
dist2st_and_end=5000,
design_width=600,
design_height=1000,
barthickness=20);

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

%map_assoc2gene4covidsexgwas(
gwas_dsd=FM.f_vs_m_mixedpop,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
AssocPVars=pval gwas1_p gwas2_p,
ZscoreVars=diff_zscore gwas1_z gwas2_z
);


*/


