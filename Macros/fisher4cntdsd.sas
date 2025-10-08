%macro fisher4cntdsd(dsn=, case1var=, case0var=, ctr1var=, ctr0var=, byvars=, outdsd=);
data &outdsd;
set &dsn;
caseWMutation=&case1var;
if caseWMutation=. then caseWMutation=0;
caseWOMutation=&case0var;
if caseWOMutation=. then caseWOMutation=0;
controlWMutation=&ctr1var;
if controlWMutation=. then controlWMutation=0;
controlWOMutation=&ctr0var; 
if controlWOMutation=. then controlWOMutation=0;
/* add 1 to all cells if any cell is 0 */
array x{*} caseWMutation caseWOMutation controlWMutation controlWOMutation;
do i=1 to 4;
 if x{i}=0 then tag=1;
end;
if tag=1 then do;
 do i=1 to 4;
  x{i}=x{i}+1;
  end;
end;
drop i tag &case0var &case1var &ctr0var &ctr1var;
/* if _n_<100; */
run;
proc sort data=&dsn;
by &byvars;
proc transpose data=&outdsd out=&outdsd._trans(rename=(col1=cnt));
var _numeric_;
by &byvars;
run;
data &outdsd._trans;
set &outdsd._trans;
type=substr(_name_,1,4);
mut=prxchange("s/(case|control)(W|WO)Mutation/$2/",-1,_name_);
drop _name_;
run;

proc sort data=&outdsd._trans;
by &byvars type mut;
run;
/* ods trace on; */
ods select none;
ods output FishersExact=FishersExact RelativeRisks=RelativeRisks;
proc freq data=&outdsd._trans order=data;
table type*mut/fisher or;
weight cnt;
by &byvars;
run;
ods select all;
/* ods trace off; */
data RelativeRisks(rename=(Value=OR));
set RelativeRisks;
where studytype="Case-Control (Odds Ratio)";
keep &byvars Value LowerCL UpperCL;
run;
data FishersExact(rename=(nvalue1=fisher_P));
set FishersExact;
where Label1="Two-sided Pr <= P";
keep &byvars nvalue1;
run;
proc sql;
create table &outdsd as
select *
from Fishersexact 
natural join
RelativeRisks;
%mend fisher4cntdsd;

/*Demo codes:;
*Import and transform the data;
x cd /research/groups/cab/projects/automapper/common/zhongshan/Analysis2025/TCGA_SNPArray_Geno/DM_GWAS;
proc import datafile="DM_tophits.geno_plus_cancertypes.txt" out=work.geno dbms=tab replace;
getnames=yes;
run;

*Use the macro to prepare data for fisher4cntdsd;
%prep_numgeno4fisher(
dsin=work.geno,
snplist=rs11749915_T rs2209313_A,
outds=geno4fisher,
byvars=cancertype
);

%fisher4cntdsd(
dsn=geno4fisher, 
case1var=case1var, 
case0var=case0var, 
ctr1var=ctr1var, 
ctr0var=ctr0var, 
byvars=cancertype Var, 
outdsd=geno4fisher_out
);
%ds2csv(data=geno4fisher,csvfile=./rs11749915_rs2290313_counts.csv,runmode=b);
%ds2csv(data=geno4fisher_out,csvfile=./rs11749915_rs2290313_fisherOR.csv,runmode=b);


*Original codes to prepare data for fisher4cntdsd;
data work.geno;
set work.geno;
where PHENOTYPE^=-9;
run;
data long_geno;
set geno;
array g{*} rs11749915_T     rs2209313_A;
do i=1 to dim(g);
  GT=g{i};
  Var=vname(g{i});
  output;
end;
drop i rs11749915_T     rs2209313_A;
run;
proc sort data=long_geno;by cancertype Var GT;run;
proc print data=long_geno(obs=10);run;
*Make dominant model;
data long_geno;
set long_geno;
if GT>=1 then GT=1;
else if GT=0 then GT=0;
else GT=.;
run;
proc freq data=long_geno noprint;table GT*Phenotype/list out=gt_frq;by CancerType Var;run;
data gt_frq;
set gt_frq;
if GT=0 and Phenotype=1 then grpname="case0var";
else if GT=1 and Phenotype=1 then grpname="case1var";
else if GT=0 and Phenotype=2 then grpname="ctr0var";
else if GT=1 and Phenotype=2 then grpname="ctr1var";
keep cancertype Var grpname count;
run;
proc sort data=gt_frq;by cancertype Var grpname;run;
proc transpose data=gt_frq out=geno4fisher(drop=_name_ _label_);
by cancertype Var;
id grpname;
var count;
run;
proc print data=geno4fisher(obs=10);run;




*/