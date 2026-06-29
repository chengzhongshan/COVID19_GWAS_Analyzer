/* Exercises Macros/Find_duplicates.sas — pulls every record whose
 * key value appears more than once in the input table. Implementation
 * uses a single PROC SQL self-join via "where key in (... having
 * count(*) > 1)", which is a clean shape for finding SNP IDs that
 * span multiple cohorts in a stacked GWAS results table.
 */

%macro Find_duplicates(inputdsd,key,outputdsd);
proc sql;
create table &outputdsd as
 select * from &inputdsd as A1
   where A1.&key in
   (select &key from &inputdsd
   group by &key having count(*)>1)
   ;
quit;
proc sort data=&outputdsd;by &key;run;
proc print data=&outputdsd;run;
%mend Find_duplicates;

/* Stacked GWAS-style table: a few SNPs appear in both HGI_B1 and
 * HGI_B2 (case/control phenotype shifts between releases). The macro
 * keeps every row whose snp shows up more than once. */
data snp_records;
length snp $12 cohort $8;
input snp $ cohort $ chrom pos pvalue;
datalines;
rs16831827 hgi_b1 2 135874281 0.000003
rs16831827 hgi_b2 2 135874281 0.0008
rs1234567  hgi_b1 1 123456789 0.001
rs7654321  hgi_b1 3 234567890 0.05
rs7654321  hgi_b2 3 234567890 0.0002
rs9999999  hgi_b1 7 333333333 0.0001
rs1112223  hgi_b1 11 50505050 0.7
;
run;

%Find_duplicates(snp_records, snp, dup_snps);
