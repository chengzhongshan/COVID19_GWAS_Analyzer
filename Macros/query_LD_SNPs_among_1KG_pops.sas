%macro query_LD_SNPs_among_1KG_pops(
/*https://rest.ensembl.org/documentation/info/ld_id_get
Computes and returns LD values between the given variant 
and all other variants in a window centered around the 
given variant. The window size is set to 500 kb.*/
snp=rs17425819,
outdsd=out,
pop=GBR /*Provide one population of the 1000 Genome phase 3 populations: CHB, CEU, ...;
Can not be empty!*/
);

filename G temp;
%if %length(&pop)>0 %then %do;
  *Query in one population;
  *KHV?content-type=application/json/;
/*  %let ensemblurl=%bquote(%nrbquote(https://rest.ensembl.org//ld/human/)&snp%nrbquote(/1000GENOMES:phase_3:)&pop%nrstr(?content-type=application/json));*/
*bquote would be enough and the simplest method to quote the http url;
%let ensemblurl=%bquote(https://rest.ensembl.org//ld/human/&snp/1000GENOMES:phase_3:&pop?content-type=application/json);
 %end;
%else %do; 
  %put please provide at least one population from the 1000 Genome Project, such as GBR, AFR, CHB, JPT, and others;
  %abort 255;
%end;
%put Your query url is &ensemblurl;
/*%abort 255;*/

proc http url="&ensemblurl" method="get"
verbose out=G;
run;

/*data _null_;*/
/*rc=jsonpp('G','log');*/
/*run;*/

libname J Json fileref=G;
proc datasets lib=J;
run;
/*proc print data=J.root;*/
/*run;*/

data &outdsd(keep=r2_&pop d_prime_&pop SNP);
set J.root;
rename r2=r2_&pop d_prime=d_prime_&pop variation2=SNP;
run;
data &outdsd(rename=(r2=r2_&pop));
set &outdsd;
r2=r2_&pop+0;
drop r2_&pop;
run;

filename G clear;
libname J clear;

%mend;

/*Demo:;
%debug_macro;
%query_LD_SNPs_among_1KG_pops(
snp=rs17425819,
outdsd=out_GBR,
pop=GBR 
);
%query_LD_SNPs_among_1KG_pops(
snp=rs17425819,
outdsd=out_CHB,
pop=CHB
);
proc sql;
create table combined as 
select *
from out_CHB
natural full join
out_GBR;

*/





