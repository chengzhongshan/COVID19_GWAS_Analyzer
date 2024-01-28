%macro import_mult_numbat_scASE(
ase_dir=,	/*a dir containing numbat scASE results for all samples, with each sample has a single subdir*/
outdsd4all=, /*Output scASE data for all samples*/
gene_DP_cutoff=10,/*Coverage cutoff for all snps in a single gene*/
out4all_cell_gene_summary=	/*cell gene summary for all samples*/
);

%list_files4dsd(dir=&ase_dir,file_rgx=sample_allele_counts.tsv.gz,dsdout=_gzfiles);
%let totfiles=%totobsindsd(mydata=_gzfiles);

proc sql noprint;
select fullpath into: f1-: f%left(&totfiles)
from _gzfiles;

%do i=1 %to &totfiles;
*for debugging;
/*%do i=1 %to 2;*/
%let file=&&f&i; 
%import_numbat_scASE( 
file=&file, 
outdsd=_sc&i, 
gene_DP_cutoff=&gene_DP_cutoff, 
out4cell_gene_summary=_sc_summary&i 
); 

data _sc&i;
length ID $50.;
set _sc&i;
ID=scan("&file",3,'\/');
ID=prxchange('s/sc_results4//',1,ID);
run;

data _sc_summary&i;
length ID $50.;
set _sc_summary&i;
ID=scan("&file",3,'\/');
ID=prxchange('s/sc_results4//',1,ID);
run;
%end;
%Union_Data_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=^_sc\d,dsdout=&outdsd4all);
data &outdsd4all;set &outdsd4all;drop dsd;
%Union_Data_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=^_sc_summary\d,dsdout=&out4all_cell_gene_summary);
data &out4all_cell_gene_summary;set &out4all_cell_gene_summary;drop dsd;run;

proc datasets lib=work noprint;
delete _sc: _gzfiles;
run;

%mend;
/*Demo codes:;

x cd "E:\scASE";
%macroparas(macrorgx=obs);
%debug_macro;

%import_mult_numbat_scASE(
ase_dir=E:/scASE,
outdsd4all=Combined_scASE, 
gene_DP_cutoff=10,
out4all_cell_gene_summary=Combined_scASE_summary
);

proc import datafile='E:\scASE\tgt_genes4imprinting.csv' dbms=csv out=tgt_genes replace;
getnames=yes;guessingrows=max;
run;
proc sql;
create table sc4tgt as
select a.*
from Combined_scase as a,
         tgt_genes as b
				 where a.gene=b.genesymbol;
*/
