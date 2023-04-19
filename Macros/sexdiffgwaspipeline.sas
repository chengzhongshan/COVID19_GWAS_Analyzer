
%macro sexdiffgwaspipeline(
male_gwas=,
female_gwas=,
snp_varname=SNP,
chr_varname=chr,
pos_varname=BP,
beta_varname=beta,
se_varname=se,
p_varname=P,
Allele1_varname=A1,
Allele2_varname=A2,
MAF_varname=AF_Allele2,
MAFcutoff=0.05,
gwasout=out);

/*proc import datafile="female.20016_irnt_Fluid_intelligence_score.txt" dbms=tab out=female replace;*/
/*getnames=yes;guessingrows=500000;*/
/*run;*/
/*proc import datafile="male.20016_irnt_Fluid_intelligence_score.txt" dbms=tab out=male replace;*/
/*getnames=yes;guessingrows=500000;*/
/*run;*/

*Can not use '\t', need to use '	' for strrgx and newstr4rep;
%let tmpdir=%curdir;

%replacestrinfile(
file=&female_gwas,
strrgx=X	,
newstr4rep=23	,
casesensitive=0,
outdir=&tmpdir,
outprefix=modified.,
firstobs=1,
obs=max
);
*The above macro will replace X with 23 and generate a new file with prefix 'modifed'.;
proc import datafile="&tmpdir/modified.&female_gwas" dbms=tab out=female replace;
getnames=yes;guessingrows=500000;
run;

%replacestrinfile(
file=&male_gwas,
strrgx=X	,
newstr4rep=23	,
casesensitive=0,
outdir=&tmpdir,
outprefix=modified.,
firstobs=1,
obs=max
);
proc import datafile="&tmpdir/modified.&male_gwas" dbms=tab out=male replace;
getnames=yes;guessingrows=500000;
run;

%del_file_with_fullpath(fullpath=&tmpdir/modified.&female_gwas);
%del_file_with_fullpath(fullpath=&tmpdir/modified.&male_gwas);


/*
%ImportFilebyScan(file=&female_gwas
                    ,dsdout=female
                    ,firstobs=1
                    ,dlm='09'x
                    ,ImportAllinChar=1
                    ,MissingSymb=NaN
);

%ImportFilebyScan(file=&male_gwas
                    ,dsdout=male
                    ,firstobs=1
                    ,dlm='09'x
                    ,ImportAllinChar=1
                    ,MissingSymb=NaN
);

*The above codes are too slow;


*Change chr 'X' as 23;
data female;
set female;
if &chr_varname="X" then &chr_varname="23";
data male;
set male;
if &chr_varname="X" then &chr_varname="23";
run;

%char2num_dsd(dsdin=female,
                 vars=&chr_varname &pos_varname &beta_varname &se_varname &p_varname &MAF_varname,
                 dsdout=&GWAS_dsdout)
%char2num_dsd(dsdin=male,
                 vars=&chr_varname &pos_varname &beta_varname &se_varname &p_varname &MAF_varname,
                 dsdout=&GWAS_dsdout);;
*/


*Filter gwas with MAF;
data female;
set female;
where &MAF_varname>=&MAFcutoff;
data male;
set male;
where &MAF_varname>=&MAFcutoff;
run;

/*combine assoc of female and male*/
proc sql;
create table both as
select a.&snp_varname,
       a.&chr_varname,
       a.&pos_varname,
       a.&Allele1_varname,
       a.&Allele2_varname,
       (a.&beta_varname-b.&beta_varname)/(sqrt(a.&se_varname**2+b.&se_varname**2)) as diff_zscore,
	   a.&p_varname as female_P,
       b.&p_varname as male_P
from female as a,
     male as b
where a.&snp_varname=b.&snp_varname;

/*proc gplot data=both;*/
/*plot female_Z*male_Z;*/
/*run;*/
/**/
proc univariate data=both;
var diff_zscore;
histogram diff_zscore;
run;

*Overlap histogram;
/*proc sgplot data=both;*/
/**/
/*  title 'Distribution of intelligence GWAS by sex';*/
/**/
/*  histogram female_Z/transparency=0.2;*/
/**/
/*  histogram male_Z/transparency=0.2;*/
/**/
/*  xaxis display=(nolabel);*/
/**/
/*  yaxis grid;*/
/**/
/*  keylegend / location=inside position=topright across=1;*/
/**/
/*  run;*/

%zscroe2p(dsdin=both,Zscore_var=diff_zscore,dsdout=&gwasout);

%manhattan(dsdin=&gwasout,
           pos_var=&pos_varname,
           chr_var=&chr_varname,
           P_var=Pval,
           logP=1);
/*proc sort data=Assoc nodupkeys;*/
/*by &snp_varname;*/
/*run;*/
%QQplot(dsdin=&gwasout,P_var=Pval);
%Lambda_From_P(P_dsd=&gwasout,P_var=Pval,case_n=,control_n=,dsdout=lambdaout);

%mend;

/*Demo:
*Note: two gwas should have all required vars with the same names;

options mprint mlogic symbolgen;

x cd "I:\Intelligence_GWAS";
%head(file=male.20016_irnt_Fluid_intelligence_score.txt);
%sexdiffgwaspipeline(
male_gwas=male.20016_irnt_Fluid_intelligence_score.txt,
female_gwas=female.20016_irnt_Fluid_intelligence_score.txt,
snp_varname=SNP,
chr_varname=chr,
pos_varname=BP,
beta_varname=beta,
se_varname=se,
p_varname=P,
Allele1_varname=A1,
Allele2_varname=A2,
MAF_varname=AF_Allele2,
MAFcutoff=0.1,
gwasout=out);

*/
