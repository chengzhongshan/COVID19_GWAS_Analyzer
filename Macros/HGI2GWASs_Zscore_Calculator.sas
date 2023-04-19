
%macro HGI2GWASs_Zscore_Calculator(
gwas1_txt_file=COVID19_HGI_B1_ALL_20201020.txt,
gwas2_txt_file=COVID19_HGI_B2_ALL_leave_23andme_20201020.txt,
dsdout=B1_vs_B2,
HGI_release_num=7	/*before release 7, such as 4, 5, and 6, the input data format are same but different from 7*/
);

*For release 7;
/*CHR POS REF ALT SNP all_meta_N all_inv_var_meta_beta all_inv_var_meta_sebeta 
all_inv_var_meta_p 

These columns were not included in r6, r5, and r4;
all_inv_var_meta_cases all_inv_var_meta_controls all_inv_var_meta_effective 

all_inv_var_het_p lmso_inv_var_beta lmso_inv_var_se lmso_inv_var_pval all_meta_AF rsid 

These columns were not included in r6, r5, and r4;
b38_chr b38_pos b38_ref b38_alt liftover_info
*/

%if &HGI_release_num>6 %then %do;
data B1;
infile "&gwas1_txt_file" dsd dlm='09'x lrecl=32767 truncover obs=max firstobs=2;
input CHR POS :12. REF :$8. ALT :$8. chrpos :$20. all_meta_N all_inv_var_meta_beta :12. all_inv_var_meta_sebeta :12. 
all_inv_var_meta_p :12.	all_inv_var_meta_cases :12. all_inv_var_meta_controls :12. all_inv_var_meta_effective :12. 
 all_inv_var_het_p lmso_inv_var_beta lmso_inv_var_se lmso_inv_var_pval all_meta_AF SNP :$20.;
z=all_inv_var_meta_beta/all_inv_var_meta_sebeta;
run;

/*%File_Head(filename="COVID19_HGI_B2_ALL_leave_23andme_20201020.txt",n=10);*/
data B2;
infile "&gwas2_txt_file" dsd dlm='09'x lrecl=32767 truncover obs=max firstobs=2;
input CHR POS :12. REF :$8. ALT :$8. chrpos :$20. all_meta_N all_inv_var_meta_beta :12. all_inv_var_meta_sebeta :12. 
all_inv_var_meta_p :12.	all_inv_var_meta_cases :12. all_inv_var_meta_controls :12. all_inv_var_meta_effective :12. 
 all_inv_var_het_p lmso_inv_var_beta lmso_inv_var_se lmso_inv_var_pval all_meta_AF SNP :$20.;
z=all_inv_var_meta_beta/all_inv_var_meta_sebeta;
run;
%end;
%else %do;
data B1;
infile "&gwas1_txt_file" dsd dlm='09'x lrecl=32767 truncover obs=max firstobs=2;
*CHR POS REF ALT SNP all_meta_N all_inv_var_meta_beta all_inv_var_meta_sebeta all_inv_var_meta_p all_inv_var_het_p all_meta_sample_N all_meta_AF rsid;
input CHR POS :12. REF :$8. ALT :$8. chrpos :$20. all_meta_N all_inv_var_meta_beta :12. all_inv_var_meta_sebeta :12. all_inv_var_meta_p :12.
 all_inv_var_het_p all_meta_sample_N all_meta_AF SNP :$20.;
z=all_inv_var_meta_beta/all_inv_var_meta_sebeta;
run;

/*%File_Head(filename="COVID19_HGI_B2_ALL_leave_23andme_20201020.txt",n=10);*/
data B2;
infile "&gwas2_txt_file" dsd dlm='09'x lrecl=32767 truncover obs=max firstobs=2;
*CHR POS REF ALT SNP all_meta_N all_inv_var_meta_beta all_inv_var_meta_sebeta 
all_inv_var_meta_p all_inv_var_het_p all_meta_sample_N all_meta_AF rsid;
input CHR POS :12. REF :$8. ALT :$8. chrpos :$20. all_meta_N all_inv_var_meta_beta :12. all_inv_var_meta_sebeta :12. all_inv_var_meta_p :12.
 all_inv_var_het_p all_meta_sample_N all_meta_AF SNP :$20.;
z=all_inv_var_meta_beta/all_inv_var_meta_sebeta;
run;
%end;

data B1;
set B1;
if SNP="NA" then SNP=chrpos;
keep snp z all_inv_var_meta_beta all_inv_var_meta_sebeta;
run;

data B2;
set B2;
if SNP="NA" then SNP=chrpos;
keep snp z all_inv_var_meta_beta all_inv_var_meta_sebeta SNP;
run;

proc sql;
create table &dsdout as
select a.snp, a.z as b1_z, a.all_inv_var_meta_beta as b1_beta, a.all_inv_var_meta_sebeta as b1_se,
							b.z as b2_z, b.all_inv_var_meta_beta as b2_beta, b.all_inv_var_meta_sebeta as b2_se
from B1 as a, B2 as b
where a.snp=b.snp;
/*data B1_vs_B2_;*/
/*set B1_vs_B2(obs=1000);*/
/*run;*/
proc export data=&dsdout outfile="&dsdout..zscore.txt" replace;
run;

/*proc import datafile ="&dsdout..zscore.txt" dbms=tab out=B1_vs_B2 replace;*/
/*run;*/
/*symbol v=dot h=1 c=darkred;*/
/*axis1 order=(-10 to 20 by 5) label=("GWAS1: &gwas1_txt_file" f=arial h=8);*/
/*axis2 order=(-10 to 20 by 5) label=("GWAS2: &gwas2_txt_fil" f=arial h=8);*/
/*proc gplot data=B1_vs_B2;*/
/*plot b1_z*b2_z/haxis=axis2 vaxis=axis1;*/
/*run;*/

%mend;

/*Demo:

x cd "J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\COVID19_HG\covid19_hg_matlab\COVID19_hosp_vs_not_hosp_B1_ALL";

%HGI2GWASs_Zscore_Calculator(
gwas1_txt_file=COVID19_HGI_B1_ALL_20201020.txt,
gwas2_txt_file=COVID19_HGI_B2_ALL_leave_23andme_20201020.txt,
dsdout=B1_vs_B2,
HGI_release_num=4
);

*/





