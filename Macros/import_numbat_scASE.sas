%macro import_numbat_scASE(/*Function annotation: Import Numbat generated single cell ASE read matrix 
and perform descriptive summary for genes passed the depth threshold in each single cell*/
file=,/*fullpath to Numbat generated scASE sample_allele_counts.tsv.gz file*/
outdsd=sc,/*Output for unfiltered scASE read count dataset*/
gene_DP_cutoff=10,/*a threshold of total number of reads for all SNPs mapped to each gene to exclude genes with low coverage ASE depth*/
out4cell_gene_summary=sc_summary /*Output dataset containg the number of genes passed the DP threshold in each single cell*/
);
%ImportFileHeadersFromZIP(
zip=&file,
filename_rgx=.,
obs=2,
sasdsdout=&outdsd,
deleteZIP=0,
infile_command=%str(
firstobs=2 obs=max dlm='09'x truncover;
input cell :$50. snp_id :$20. chr pos cM Ref $1. Alt :$10. AD DP GT :$10. gene :$100.;
),
use_zcat=0
);

*Check how many genes have sc-ASE results;
proc sql;
create table sc as
select *
from &outdsd (where=(gene^=""))
group by cell,gene
having sum(DP)>&gene_DP_cutoff
order by cell,gene;
/*data sc1;*/
/*set sc(obs=1000);*/
/*run;*/

proc summary data=sc mean sum;
var AD DP;
by cell gene;
output out=&out4cell_gene_summary mean=mean_AD mean_DP sum=sum_AD sum_DP;
run;
proc freq data=&out4cell_gene_summary noprint;
table cell/list out=cell_gene_cnts(drop=percent);
run;
*It turns out that very few genes (n~3) having ASE in each cell;
*Thus it is necessary to aggregate read counts of all single cell type for calculating ASE.;

%mend;

/*Demo codes:;
%let file=E:\scASE\sc_results4FCA7196224\sample_allele_counts.tsv.gz;
%import_numbat_scASE(
file=&file,
outdsd=sc,
gene_DP_cutoff=10,
out4cell_gene_summary=sc_summary 
);

*/
