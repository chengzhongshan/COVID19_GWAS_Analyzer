%include "%sysfunc(pathname(HOME))/Macros/importallmacros_ue.sas";
%importallmacros_ue;

%let gwas=/home/cheng.zhong.shan/data/LongCOVID/CombineLongCOVIDGWAS.txt.gz;

%ImportFileHeadersFromZIP(
zip=&gwas,/*Only provide file with .gz, .zip, or common text file without comporession*/
filename_rgx=.,
obs=max,
sasdsdout=gwas,
deleteZIP=0,
infile_command=%str(firstobs=2 obs=max dlm='09'x truncover dsd;
input chrom pos rsid :$20. ref :$1. 
alt :$1. neg_log_pvalue4W2 beta4W2 
stderr_beta4W2 alt_allele_freq4W2 
neg_log_pvalue4W1 beta4W1 
stderr_beta4W1 alt_allele_freq4W1 
neg_log_pvalue4N2 beta4N2 
stderr_beta4N2 alt_allele_freq4N2 
neg_log_pvalue4N1 beta4N1 
stderr_beta4N1 alt_allele_freq4N1;
p4W2=10**(-neg_log_pvalue4W2);
p4W1=10**(-neg_log_pvalue4W1);
p4N1=10**(-neg_log_pvalue4N1);	
p4N2=10**(-neg_log_pvalue4N2);
drop neg_log_pvalue:;
),
use_zcat=0
);
*No need to do this, as the Manhattan macro requires to have numeric chr notation;
/* %chr_format_exchanger( */
/* dsdin=gwas, */
/* char2num=0, */
/* chr_var=chrom, */
/* dsdout=gwas); */
proc print data=gwas(obs=10);
run;


%let chrname=chr6;
%let minst=41000000;
%let maxend=42000000;
libname H "/home/cheng.zhong.shan/data/GTEx_V8";
%get_sigs_from_HGI_R7_by_ChrPos(
gwas_names=A2_ALL A2_AFR A2_EAS A2_SAS A2_EUR,
chrpos_or_rsids=&chrname:&minst-&maxend,
dsdout=H.HGI_FOXP4_signals
);
*modify variables and only use rsid to match hg38 and hg19 data;
data severe_covid;
set H.HGI_FOXP4_signals;
keep rsid dsd beta se p;
dsd=prxchange('s/work.HGI_GWASA2_/A2_/',-1,dsd);
where rsid^="";
run;
%long2wide4multigrpsSameTypeVars(
long_dsd=severe_covid,
outwide_dsd=severe_covid_wide,
grp_vars=rsid,/*If grp_vars and SameTypeVars are overlapped,
the macro will automatically only keep it in the grp_vars; 
grp_vars can be multi vars separated by space, which 
can be numeric and character*/
subgrpvar4wideheader=dsd,/*This subgrpvar will be used to tag all transposed SameTypeVars 
in the wide table, and the max length of this var can not be >32!*/
dlm4subgrpvar=.,/*string used to split the subgrpvar if it is too long*/
ithelement4subgrpvar=1,/*Keep the nth splitted element of subgrpvar and use it for tag 
in the final wide table*/
SameTypeVars=_numeric_, /*These same type of vars will be added with subgrp tag in the 
final wide table; Make sure they are either numberic or character vars and not 
overlapped with grp_vars and subgrpvar!*/
debug=0 /*print the first 2 records for the final wide format dsd*/
);
data severe_covid_wide;
set severe_covid_wide;
drop pos_:;
run;



*Note: the gwas dataset is not sorted by chr;
*It will take too much time to run it directory using the Manhattan plot macro;
%QueryGTEx4GeneID(
geneids=FOXP4,/*For Apobec3a*/
genomeBuild=hg38,/*hg38, but hg19 is not supported by GTEx*/
outdsd=gene_info
);
proc sql noprint;
select start - 10000000,end + 10000000, prxchange("s/^chr//",-1,chromosome) 
into: stpos, : endpos, :chrnum
from gene_info;

data tgt;
set gwas;
where chrom=&chrnum and pos between &stpos and &endpos;
run;
*Add severe covid associations;
proc sql;
create table tgt as 
select a.*,b.*
from tgt as a,
     severe_covid_wide as b
where a.rsid=b.rsid;
      

proc sort data=tgt;by chrom and pos;
run;
proc print data=tgt;
where rsid="rs9367106";
run;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

/* %debug_macro; */
%Gene_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro;
Note: this macro will use the gene name to query GTF and GWAS, and then
make local Manhattan plot with the top SNP at the center around the query gene!*/
gwas_dsd=tgt,
gwas_chr_var=chrom,/*GTF uses numeric chr notation; ensure the type of chr is consistent with input gwas dsd*/
gwas_AssocPVars=p4N2 p_A2_ALL p_A2_EAS p_A2_SAS p_A2_EUR p_A2_AFR,
Gene_IDs=FOXP4,
dist2Gene=100000,/*in bp; left or right size distant to each target Gene for the Manhattan plot*/
SNP_Var_GWAS=rsid,
Pos_Var_GWAS=pos,
gtf_dsd=FM.GTF_HG38,
Gene_Var_GTF=Genesymbol,
GTF_Chr_Var=chr,
GTF_ST_Var=st,
GTF_End_Var=end,
ZscoreVars=beta4N2 beta_A2_ALL beta_A2_EAS beta_A2_SAS beta_A2_EUR beta_A2_AFR,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
design_width=1000, 
design_height=1000, 
barthickness=10, /*gene track bar thinkness*/
dotsize=6, 
dist2sep_genes=1000000,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(p4N2>=0), /*where condition to filter input gwas_dsd*/
gwas_labels_in_order=Long_COVID Severe_COVID_ALL Severe_COVID_EAS Severe_COVID_SAS Severe_COVID_EUR Severe_COVID_AFR 
/*The order will be from down to up in the final tracks*/
);
*It is possible to export the tgt dsd into local computer for further analyses;
*%ds2csv(data=tgt,csvfile="FOXP4_Assoc_signals.csv",runmode=b);
