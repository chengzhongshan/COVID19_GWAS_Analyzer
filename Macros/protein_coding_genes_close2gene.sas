%macro protein_coding_genes_close2gene(
gtf=gtf_hg38,
chr4gene=2,
dist=1e6,
genesymbol=SF3B1,
outdsd=combined_genes_by_dist,
macrvar4genes=nearby_genes /*Create a macro var to save these genes separated by space*/
);
%global &macrvar4genes;
data input;
set &gtf;
where chr=&chr4gene and ensembl_transcript contains "protein_coding";
run; 
%get_nearby_genes_by_dist( 
gtf=input, 
dist=&dist, 
outputdsd=&outdsd, 
output_cnts4genes=gene_cnts, 
max_gene_cnts4histgram=100 
); 
data &outdsd;
set &outdsd;
where genesymbol="&genesymbol";
run;
title "A macro variable called nearby_genes was created to contain these genes for &genesymbol:";
proc sql;
select nearby_genes into: &macrvar4genes separated by ' '
from &outdsd
where not prxmatch("/(ENSG|-)/",nearby_genes);
title "";
%mend;
/*Demo codes:;
libname G "E:\LongCOVID_HGI_GWAS"; 
%protein_coding_genes_close2gene(
gtf=G.gtf_hg38,
chr4gene=2,
dist=1e6,
genesymbol=SF3B1,
outdsd=combined_genes_by_dist
);
%put &nearby_genes;
*/

