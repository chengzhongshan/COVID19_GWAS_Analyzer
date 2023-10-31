%macro calc_pairwise_LD_among_1KG_pops(
snp1=,
snp2=,
outdsd=out,
pop=GBR /*Provide one population of the 1000 Genome phase 3 populations: CHB, CEU, ...;
if empty, it will query all populations and calcuate pairwise LD;*/
);

filename G temp;
%if %length(&pop)>0 %then %do;
  *Query in one population;
  %let ensemblurl=%bquote(%nrbquote(https://rest.ensembl.org//ld/human/pairwise/)&snp1/&snp2%nrbquote(?population_name=1000GENOMES:phase_3:)&pop%nrstr(;content-type=application/json));
 %end;
%else %do; 
 *Query among all populations;
  %let ensemblurl=%nrbquote(https://rest.ensembl.org//ld/human/pairwise/)&snp1/&snp2%nrbquote(?content-type=application/json);
%end;
%put Your query url is &ensemblurl;
/*%abort 255;*/

proc http url="&ensemblurl" method="get"
verbose  out=G;
run;
data _null_;
rc=jsonpp('G','log');
run;

libname J Json fileref=G;
proc datasets lib=J;
run;
proc print data=J.root;
run;

data &outdsd;
set J.root;
keep variation1 variation2 r2 d_prime population_name;
run;
filename G clear;
libname J clear;

%mend;

/*Demo:;
%debug_macro;
%calc_pairwise_LD_among_1KG_pops(
snp1=rs17425819,
snp2=rs7850484,
outdsd=out,
pop=GBR 
);

*/





