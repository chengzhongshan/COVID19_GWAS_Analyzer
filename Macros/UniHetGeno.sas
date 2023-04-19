%macro UniHetGeno(dsdin,geno,dsdout);
data &dsdout(drop=Het);
retain Het '00';
set &dsdin;
&geno=strip(left(&geno));
if substr(&geno,1,1)^=substr(&geno,2,1) and Het='00' then Het=&geno;
if substr(&geno,1,1)^=substr(&geno,2,1) and Het^=&geno then &geno=Het;
run;
%mend;

/*

%UniHetGeno(dsdin=topsnp,geno=geno,dsdout=x);

*/
