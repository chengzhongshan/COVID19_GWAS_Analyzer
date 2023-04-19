
%macro DiffTwoCorrelatedGWAS(/*Note: only common SNPs will be kept*/
gwas1dsd=,
gwas2dsd=,
nctrl=,/*Number of samples for the common grp between gwas1 and gwas2*/
ngwas1=,/*Total sample size for gwas1*/
ngwas2=,/*Total sample size for gwas2*/
gwas1chr_var=,
gwas1pos_var=,
snp_varname=rsid,
beta_varname=beta,
se_varname=se,
p_varname=P,
gwasout=out,
stdize_zscore=1 /*Stardize zscore by mean and scaled with std, 
                 which will make the qqplot more reasonable*/
);

options compress=yes;
/*combine assoc of female and male*/
*Also keep beta but not se, as se can be re-calculated by z/beta;
*SAS OnDemand out of memory if including a.&beta_varname as gwas1_beta,b.&beta_varname as gwas2_beta;
*a.&beta_varname as gwas1_beta,b.&beta_varname as gwas2_beta,;

*Note: the cov of two se is not as that in traditional meta-analysis;
*In fact, the following does not improve the final qqplot of p values of these diff_zscore;

proc sql;
create table both as
select a.&snp_varname,
       (a.&beta_varname-b.&beta_varname)/(sqrt(a.&se_varname**2+b.&se_varname**2-2*(1/&nctrl+(a.&beta_varname/b.&se_varname)*(b.&beta_varname/a.&se_varname)/(&ngwas1+&ngwas2)))) 
       as diff_zscore,
	   a.&p_varname as gwas1_P,
       b.&p_varname as gwas2_P,
       a.&beta_varname/a.&se_varname as gwas1_z,
       b.&beta_varname/b.&se_varname as gwas2_z,
       a.&gwas1chr_var as chr,a.&gwas1pos_var as pos
from &gwas1dsd as a,
     &gwas2dsd as b
where a.&snp_varname=b.&snp_varname;

%if &stdize_zscore=1 %then %do;
*Standardize zscore based on std method;
proc stdize data=both method=std out=both pstat;
   title2 'METHOD=STD';
   var diff_zscore;
run;
%end;

/* *The above works for standardization! */

/* *Adjusted by mean of zscore, also needed to be scaled by std; */
/* proc sql noprint; */
/* select mean(diff_zscore) into: mean_zscore, std(diff_zscore) into: zscore_std */
/* from both;  */
/* update both */
/* set diff_zscore=(diff_zscore-(&mean_zscore))/&zscore_std; */
/* quit; */

options compress=no;

/*proc gplot data=both;*/
/*plot female_Z*male_Z;*/
/*run;*/
/**/
/* proc univariate data=both plots; */
/* var diff_zscore; */
/* var gwas1_z gwas2_z; */
/* var gwas1_beta gwas2_beta; */
*histogram diff_zscore;
/* run; */

*Overlap histogram;
/*proc sgplot data=both;*/
/**/
/*  title 'Distribution of intelligence GWAS by sex';*/
/**/
/*  histogram gwas1_Z/transparency=0.2;*/
/**/
/*  histogram gwas2_Z/transparency=0.2;*/
/**/
/*  xaxis display=(nolabel);*/
/**/
/*  yaxis grid;*/
/**/
/*  keylegend / location=inside position=topright across=1;*/
/**/
/*  run;*/

%zscroe2p(dsdin=both,Zscore_var=diff_zscore,dsdout=both);

%manhattan(dsdin=both,
           pos_var=pos,
           chr_var=chr,
           P_var=Pval,
           logP=1,
           dotsize=2);
/*proc sort data=Assoc nodupkeys;*/
/*by &snp_varname;*/
/*run;*/
%QQplot(dsdin=both,P_var=Pval);
%Lambda_From_P(P_dsd=both,P_var=Pval,case_n=,control_n=,dsdout=lambdaout);

/*output the dataset both as gwasout*/
proc datasets lib=work nolist;
delete &gwasout;
change both=&gwasout;
run;

%mend;

