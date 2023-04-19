%macro get_HGI_R7_GWAS(
gwas_name=, /*such as B1_ALL, B2_ALL, and C2_ALL;
furthermore, except B1, all others have subpopulation GWASs,
such as B2_AFR, B2_EAS, B2_SAS, B2_HIS;
Note: A2_HIS, C2_HIS and B2_HIS tar gz file was broken! No A1_ALL
*/
hgi_gwas=hgi_gwas_out /*sas dsd output*/
);
%let gwas_name=%upcase(&gwas_name);

%if "&gwas_name"="B1_ALL" %then
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/main/sumstats/COVID19_HGI_B1_ALL_leave_23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="B2_ALL" %then        
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/main/sumstats/COVID19_HGI_B2_ALL_leave_23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="B2_AFR" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_afr_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="B2_SAS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_sas_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="B2_EUR" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_eur_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="B2_EAS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_eas_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="B2_HIS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_B2_ALL_his_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="C2_ALL" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/main/sumstats/COVID19_HGI_C2_ALL_leave_23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="C2_AFR" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_C2_ALL_afr_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="C2_EAS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_C2_ALL_eas_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="C2_SAS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_C2_ALL_sas_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="C2_HIS" %then %do;
        %put C2_HIS tar gz file was broken;
/*         %abort 255;  */
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_C2_ALL_his_leave23andme_20220403_GRCh37.tsv.gz;

%end;
%else %if "&gwas_name"="C2_EUR" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_C2_ALL_eur_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="A2_ALL" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/main/sumstats/COVID19_HGI_A2_ALL_leave_23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="A2_HIS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_A2_ALL_his_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="A2_AFR" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_A2_ALL_afr_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="A2_EUR" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_A2_ALL_eur_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="A2_EAS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_A2_ALL_eas_leave23andme_20220403_GRCh37.tsv.gz;
%else %if "&gwas_name"="A2_SAS" %then 
        %let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_A2_ALL_sas_leave23andme_20220403_GRCh37.tsv.gz;
%else %do;
        %put Unknow gwas name &gwas_name;
        %abort 255;
%end;

%if %sysfunc(prxmatch(/ALL/,&gwas_name)) %then %do;
   %get_HGI_covid_gwas_from_HGI(gwas_url=&gwas_url,outdsd=&HGI_gwas,for_subpop=0);
%end;
%else %if %sysfunc(prxmatch(/A1/,&gwas_name)) %then %do;
*Seems that the hg38 A2_HIS GWAS was broken;
*%let gwas_url=https://storage.googleapis.com/covid19-hg-public/freeze_7/results/20220403/pop_spec/sumstats/COVID19_HGI_A2_ALL_his_leave23andme_20220403_GRCh37.tsv.gz;
*This only works for the subpop GWAS of A1;
%let wkdir=%sysfunc(getoption(work));
%delete_file_or_dir_with_fullpath(
file_or_dir_fullpath=&wkdir/gwas_gz_file.gz
);
%dwn_http_file(httpfile_url=&gwas_url,outfile=gwas_gz_file.gz,outdir=&wkdir);
/*
%ImportFileHeadersFromZIP(
zip=&wkdir/gwas_gz_file.gz,
filename_rgx=.,
obs=2,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(firstobs=1 obs=10;input;info=_infile_;),
use_zcat=0
);
%check_header_and_values(
input_dsd_or_file_or_url=x,
tgt_var_from_dsd=info,
linesep=\t,
dsdout=x_trans,
column_len=500,
header_line=1,
value_line=10,
use_zcat=0,
deleteZIP=0
);
*/

%ImportFileHeadersFromZIP(
zip=&wkdir/gwas_gz_file.gz,
filename_rgx=.,
obs=max,
sasdsdout=&hgi_gwas,
deleteZIP=1,
infile_command=%str(firstobs=2 obs=max delimiter='09'x;
input 
CHR 
POS 	:8.
REF 	:$8.
ALT 	:$8.
SNP 	:$25.
all_meta_N 
beta 
sebeta
p
cases
controls
effective
het_p
all_meta_AF
rsid  :$16.
b38_chr 
b38_pos :8.
b38_ref  :$16.
b38_alt  :$1.
liftover_info 
;
if het_p>0.05;
),
use_zcat=0
);
%end;

%else %do;
   %*The following works for other subpopulation level GWAS;
   %get_HGI_covid_gwas_from_HGI(gwas_url=&gwas_url,outdsd=&HGI_gwas,for_subpop=1);
%end;

%mend;

/*such as A1_ALL, B1_ALL, B2_ALL, and C2_ALL;
furthermore, except B1, all others have subpopulation GWASs,
such as B2_AFR, B2_EAS, B2_SAS, B2_HIS;
*/

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

%get_HGI_R7_GWAS(
gwas_name=C2_HIS, 
hgi_gwas=hgi_gwas_out
);

proc print data=hgi_gwas;
where rsid contains ('rs12628403');
run;

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.HGI_gwas,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx,
gwas_thrsd=2,
Mb_SNPs_Nearby=1,
snps=%str(rs12628403),
design_width=1000,
design_height=500
);

/* %SNP_Local_Manhattan_With_GTF( */
/* to make the genes separated better based on distance;GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro */
/* vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro */
/* var chr in this macro */
/* gwas_dsd=HGI_gwas, */
/* chr_var=chr, */
/* AssocPVars=p, */
/* SNP_IDs=rs12628403, */
/* dist2snp=500000,/*in bp; left or right size distant to each target SNP for the Manhattan plot */
/* SNP_Var=rsid, */
/* Pos_Var=pos, */
/* gtf_dsd=FM.GTF_HG19, */
/* ZscoreVars=beta,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions  */
/* design_width=1200,  */
/* design_height=500,  */
/* barthickness=10, /*gene track bar thinkness */
/* dotsize=8,  */
/* dist2sep_genes=0.2,/*Distance to separate close genes into different rows in the gene track; provide negative value */
/* to have all genes in a single row in the final gene track */
/* where_cndtn_for_gwasdsd=%str(p<1) /*where condition to filter input gwas_dsd */
/* ); */
/*  */
/* *For the long COVID snp rs9367106 located on the gene FOXP4; */
/* %Gene_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro */
/* vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro */
/* var chr in this macro; */
/* Note: this macro will use the gene name to query GTF and GWAS, and then */
/* make local Manhattan plot with the top SNP at the center around the query gene! */
/* gwas_dsd=HGI_gwas, */
/* gwas_chr_var=chr, */
/* gwas_AssocPVars=p, */
/* Gene_IDs=APOBEC3A JAK2 TMPRSS2 CD55, */
/* dist2Gene=200000,/*in bp; left or right size distant to each target Gene for the Manhattan plot */
/* SNP_Var_GWAS=rsid, */
/* Pos_Var_GWAS=pos, */
/* gtf_dsd=FM.GTF_HG19, */
/* Gene_Var_GTF=Genesymbol, */
/* GTF_Chr_Var=chr, */
/* GTF_ST_Var=st, */
/* GTF_End_Var=end, */
/* ZscoreVars=beta,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions  */
/* design_width=1000,  */
/* design_height=500,  */
/* barthickness=15, /*gene track bar thinkness */
/* dotsize=8,  */
/* dist2sep_genes=0.2,/*Distance to separate close genes into different rows in the gene track; provide negative value */
/* to have all genes in a single row in the final gene track */
/* where_cndtn_for_gwasdsd=%str(p<1) /*where condition to filter input gwas_dsd */
/* ); */


*/

