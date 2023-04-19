%macro GetMinorAllele(dsdin,geno_var,dsdout);

ods select none;
ods output OneWayFreqs=GenoFreqs;
proc freq data=&dsdin;
table &geno_var;
run;
ods listing;
ods select all;

data GenoFreqs(keep=&geno_var Percent A1 A2);
set GenoFreqs;
A1=substr(&geno_var,1,1);
A2=substr(&geno_var,2,1);
if prxmatch('/([acgtACGT]){2}/',&geno_var) and A1=A2;
run;
proc sql noprint;
create table &dsdout as
select A1,percent,&geno_var
from GenoFreqs
having percent=min(percent);
%mend;




