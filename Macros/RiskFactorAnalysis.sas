%macro RiskFactorAnalysis(dsd,pheno,age_var,tested_vars,fisher);
%let test=chisq;
%if &fisher=1 %then %let test=fisher;

proc sort data=&dsd;by &pheno;run;
proc print data=&dsd (obs=10);run;
proc univariate data=&dsd normal plot;
var &age_var;
histogram &age_var/normal (MU=EST sigma=est color=red l=1);
by &pheno;
run;

proc npar1way data=&dsd wilcoxon median;
class &pheno;
var &age_var;
run;

ods trace on;
ods output  FishersExact= FishersExact CrossTabFreqs=CrossTabFreqs;
proc freq data=&dsd;
table (&Tested_Vars)*&pheno/&test;
run;
ods trace off;

data FishersExact(keep=factor nvalue1);
length factor $10.;
set FishersExact;
factor=strip(prxchange("s/(Table |\* &pheno)//",-1,Table));
%if &fisher=1 %then %do;
where Label1="Pr <= P" or Label1="Two-sided Pr <= P";
%end;
%else %do;
where Label1="Two-sided Pr <= P";
%end;
run;

data CrossTabFreqs_Simplified(drop=Table _TYPE_ _TABLE_ Percent RowPercent Missing);
length factor $10.;
set CrossTabFreqs;
factor=strip(prxchange("s/(Table |\* &pheno)//",-1,Table));
/*filter table and only keep info for interested pheno 2*/
if _TYPE_='11' and sum(of &tested_vars)>1;
run;

data CrossTabFreqs_Simplified;
set CrossTabFreqs_Simplified;
keep factor &pheno frequency ColPercent;
run;


proc sort data=FishersExact;by factor;run;
proc sort data=CrossTabFreqs_Simplified;by factor;run;
data CrossTabFreqs_Fisher;
merge CrossTabFreqs_Simplified FishersExact(rename=(nvalue1=P));
by factor;
run;


proc tabulate data=CrossTabFreqs_Fisher;
class factor &pheno;
var frequency ColPercent P;
table factor
      ,
	  &pheno*(frequency*mean=" " ColPercent*mean=" " P*mean=" "*f=best32.);

run;

proc tabulate data=&dsd;
class &pheno;
table &pheno,n;

run;
%mend;

/*
proc import datafile="G:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Clininal_Risk_Factor_Summary_Table\Database_year_18_Chin.sav"
            out=JAK2_CLIN_INFO
            dbms=spss replace;
run;

*Note: Make sure all vars and pheno be coded with 1 or 2;

%RiskFactorAnalysis(dsd,pheno,age_var,tested_vars);


*/

/*Only for code backup;

proc format;
picture pct (round) low - high = '0009.99%'
;
run;
ods trace off;
proc tabulate data=&dsd;
class &pheno sex age_65 Age_65 Heart Liver Renal Metabolic Hemoglo Immune Neuro Pulmonary Obesity Pregnancy;
table (all)*
      (
       sex sex*pctn='%'*f=pct.
       age_65 age_65*pctn='%'*f=pct.
       Heart Heart*pctn='%'*f=pct.
       Liver Liver*pctn='%'*f=pct.
       Renal Renal*pctn='%'*f=pct.
       Metabolic Metabolic*pctn='%'*f=pct.
       Hemoglo Hemoglo*pctn='%'*f=pct.
       Immune Immune*pctn='%'*f=pct.
       Neuro Neuro*pctn='%'*f=pct.
       Pulmonary Pulmonary*pctn='%'*f=pct.
       Obesity Obesity*pctn='%'*f=pct.
       Pregnancy Pregnancy*pctn='%'*f=pct.
       )
       ,
       &pheno;
run;

proc reg data=&dsd;
model &pheno=Sex--Pregnancy/selection=stepwise
                          sle=0.10 sls=0.10;
print cli;
run;

*/

                                                 
