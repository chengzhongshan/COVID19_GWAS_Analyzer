%macro QueryLD_SNPs_at_Haploreg4(
snp=rs2564978,
LDpop=EUR,
ldThresh=0.7,
outdsd=LD_dsd
);
%let query_str=%nrstr(&query=)&snp%nrstr(&ldThresh=)&ldThresh%nrstr(&ldPop=)&LDpop%nrstr(&output=text&submit=submit);
*Note: the important ldPop is required to obtain all high LD SNPs for the query SNPs;
*If no ldPop provided, it will only return annotations for the query SNPs!;
filename hap "%sysfunc(pathname(HOME))/out.txt" lrecl=1000000000;
proc http url="https://pubs.broadinstitute.org/mammals/haploreg/haploreg.php/post"
method="POST"
in="&query_str"
out=hap
ct='application/x-www-form-urlencoded';
run;
data _null_;
rc=jsonpp('hap','log');
run;
*It seems that the following works;
proc import datafile=hap dbms=tab out=&outdsd replace;
getnames=yes;
guessingrows=max;
run;
data &outdsd;
set &outdsd;
chr=prxchange("s/Array//i",-1,chr);
run;
%mend;

/*Demo codes:;
%QueryLD_SNPs_at_Haploreg4(
snp=rs2564978,
LDpop=EUR,
ldThresh=0.7
);
*Note: some snps with high LD to the query snp do not have hg38 chr and positions;
*These snps indeed have hg19 chr and positions in the haploreg4 database;


*/

