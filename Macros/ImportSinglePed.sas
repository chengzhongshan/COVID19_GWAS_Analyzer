%macro ImportSinglePed(PedFile,outdsd,sep);
%if &sep eq %then %do;
Proc import datafile="&Pedfile" dbms=dlm out=&outdsd replace;
            delimiter=' ';
            getnames=no;guessingrows=1000;
run;

%end;
%else %do;
Proc import datafile="&Pedfile" dbms=dlm out=&outdsd replace;
            delimiter=&sep;
            getnames=no;guessingrows=1000;
run;
%end;


data &outdsd;
length geno $2.;
set &outdsd;
geno=cat(Var7,Var8);
run;

%UniHetGeno(dsdin=&outdsd,geno=geno,dsdout=&outdsd);

%char2num_dsd(dsdin=&outdsd,
              vars=var3 var4 var5 var6,
              dsdout=&outdsd);


/*Add numeric geno*/
%GetMinorAllele(dsdin=&outdsd,geno_var=geno,dsdout=MAF);
proc sql noprint;
select A1 into: M
from MAF;
data &outdsd;
set &outdsd;
num_geno=countc(geno,"&M");
if geno="00" then num_geno=.;
run;
 
%mend;
