/* Exercises Macros/calculate_binomial_P.sas — the allele-specific
 * expression (ASE) binomial test from the COVID19_GWAS_Analyzer
 * toolkit. For each row of (A1, A2) read counts it computes
 *   - tot_reads    = A1 + A2  (rows with tot_reads < cutoff are dropped)
 *   - A1A2log2Ratio = log2((A1+0.0001)/(A2+0.0001)),
 *                     clamped to ±Abs_A1A2_ratio_cutoff
 *   - Ref_Frq      = 100 * A1 / tot_reads
 *   - binomial_P   = probbnml(0.5, tot_reads, min(A1, A2))
 *   - logP         = -log10(binomial_P), capped at 500 when P==0
 *
 * The driver feeds the macro's own demo allele-count rows (taken
 * directly from the script's annotation block).
 */

%macro calculate_binomial_P(
dsdin=_last_,	/*SAS input data set for calculating binomial P*/
dsdout=,	/*output sas data set that contains the newly created binomial_P and its -logP*/
Allele1_var=V1,/*Counts for variable allele 1, usually the ref allele, such as allele 1 in ASE*/
Allele2_var=V2,/*Counts for variable allele 2, such as alele 2 in ASE*/
TotReadCutoff=20,/*Total read counts cutoff, used to delete records with total reads of alleles <= the cutoff*/
Abs_A1A2_ratio_cutoff=10,/*the largest value allowable for the absolute ratio between alele 1 and 2, with value >10 or <-10 will be assigned with value 10*/
Largest_logP=500 /*When the binomial P is too significantly close to 0, the -log(P) would be arbitarily given the value 500*/
);

data &dsdout;
set &dsdin;
tot_reads=&Allele1_var+&Allele2_var;
if tot_reads<&TotReadCutoff then delete;
A1A2log2Ratio=log2((&Allele1_var+0.0001)/(&Allele2_var+0.0001));
if A1A2log2Ratio>&Abs_A1A2_ratio_cutoff then A1A2log2Ratio=10;
else if A1A2log2Ratio<-&Abs_A1A2_ratio_cutoff then A1A2log2Ratio=-10;
Ref_Frq=100*(&Allele1_var/(tot_reads));
/*Make sure to use the smallest num for calculating bionomial P*/
if &Allele1_var-&Allele2_var>0 then do;
  binomial_P=probbnml(0.5,tot_reads,&Allele2_var+0);
end;
else do;
  binomial_P=probbnml(0.5,tot_reads,&Allele1_var+0);
end;

if (binomial_P=0) then do;
logP=500;
end;
else do;
logP=-log10(binomial_P);
end;

run;

%mend;

/* Demo data straight from Macros/calculate_binomial_P.sas annotations */
data ase_counts;
input A1 A2;
datalines;
10 100
50 50
1 100
1 5
0 100
2 100
5 100
10 100
20 100
30 100
40 100
50 100
60 100
70 100
80 100
90 100
100 100
;
run;

%calculate_binomial_P(
dsdin=ase_counts,
dsdout=binom_results,
Allele1_var=A1,
Allele2_var=A2,
TotReadCutoff=20,
Abs_A1A2_ratio_cutoff=10,
Largest_logP=500
);

proc print data=binom_results; run;
