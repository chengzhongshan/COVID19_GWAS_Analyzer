%macro gnomAD_snp_frq_analyzer(
gnomAD_file,/*copy gnomAD Population Frequencies table and save it into a txt file*/
gnomAD_snpid,/*such as 10-63699895-A-C for parsing ref and alt alleles*/
dsdout=gnomAD,/*Output sas dsd*/
csvout=gnomAD /*csv output name without appendix of .csv*/
);

*Get ref and alt alleles;
%let ref_allele=%scan(&gnomAD_snpid,3,-);
%let alt_allele=%scan(&gnomAD_snpid,4,-);

proc import datafile="&gnomAD_file" dbms=tab out=gnomAD replace; 
getnames=no;
guessingrows=max;
datarow=2;
run;

/*
Imported Columns: 
1. Population
2. Alt_cnt
3. Total_allele_cnt
4. Homo_n
5. Alt_frq

*Need to calculate:
6. Ref_cnt
7. Total_samples
8. Ref_homo_n
9. Het_n
10.Alt_homo_n
11.Ref_homo_frq
12.Het_frq
13.Alt_homo_frq
*/

data gnomAD;
set gnomAD;
rename Var1=Population
Var2=Alt_cnt
Var3=Total_allele_cnt
Var4=Homo_n
Var5=Alt_frq;
run;

data &dsdout;
set gnomAD;
Ref_cnt=Total_allele_cnt - Alt_cnt;
Het_n=Alt_cnt - Homo_n*2;
Ref_homo_n=(Ref_cnt - Het_n)/2;
Alt_homo_n=Homo_n;
Total_samples=Alt_homo_n + Ref_homo_n + Het_n;
Ref_homo_frq=100*Ref_homo_n/Total_samples;
Het_frq=100*Het_n/Total_samples;
Alt_homo_frq=100*Alt_homo_n/Total_samples;
;
run;

data gnomAD;
retain 
Population
Alt_cnt
Total_allele_cnt
Homo_n
Alt_frq
Ref_cnt
Total_samples
Ref_homo_n
Het_n
Alt_homo_n
Ref_homo_frq
Het_frq
Alt_homo_frq;
set gnomAD;
/*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/mcrolref/p0pnc7p9n4h6g5n16g6js048nhfl.htm
There are no ways to escape %&Alt_allele in open codes, can not use %%&Alt_allele or %nrstr;

*/
label 
Population="Population"
Alt_cnt="#&Alt_allele"
Total_allele_cnt="#Total Alleles"
Homo_n="#&Alt_allele./&Alt_allele"
Alt_frq="&Alt_allele.%"
Ref_cnt="&Ref_allele.%"
Total_samples="#individuals"
Ref_homo_n="#&Ref_allele./&Ref_allele homo"
Het_n="#&Ref_allele./&Alt_allele het"
Alt_homo_n="#&Alt_allele./&Alt_allele homo"
Ref_homo_frq="% of &Ref_allele./&Ref_allele"
Het_frq="% of &Ref_allele./&Alt_allele"
Alt_homo_frq="% of &Alt_allele./&Alt_allele";
set gnomAD
;
Alt_frq=100*Alt_frq;
run;

/*proc print;run;*/
%ds2csv(data=gnomAD,runmode=b,csvfile="&csvout..csv");

%mend;

/*Demo 

%importallmacros;

%gnomAD_snp_frq_analyzer(
gnomAD_file=gnomAD.txt,
gnomAD_snpid=10-63699895-A-C,
dsdout=gnomAD,
csvout=gnomAD
);

*/



