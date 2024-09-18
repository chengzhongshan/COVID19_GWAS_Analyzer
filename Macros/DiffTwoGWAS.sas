
%macro DiffTwoGWAS(/*Note: only common SNPs will be kept; 
also requires to have two allele vars common to both GWASs:
such as allele1 and allele2 in both GWAS;
duplicate snps in each GWAS will be excluded

Important: it is necessary to sort the two input GWAS by chr and pos before
applying current macro!

*/
gwas1dsd=,
gwas2dsd=,
gwas1chr_var=,
gwas1pos_var=,/*gwas1 chr and position variable names should be the same as that of the other GWAS*/
snp_varname=rsid,/*Marker id variable name for the two GWASs*/
beta_varname=beta,/*Beta variable name for the two GWASs*/
se_varname=se,/*standard error variable name should be the same for two GWASs*/
p_varname=P, /*P variable name from both two GWASs should be the same!*/
gwasout=out,
stdize_zscore=1, /*Stardize zscore by mean and scaled with std, 
                 which will make the qqplot more reasonable*/
mk_manhattan_qqplots4twoGWASs=1,
gwas1_tot=,
gwas2_tot=,
/*When the total number of samples from the two gwass
are provided, it will use sample size to adjust the
variance estimation: 
sqrt(
2*(gwas1_tot-1)*se1^2/(total_of_two_gwas-2) + 
2*(gwas2_tot-1)*se2^2/(total_of_two_gwas-2)
)
This is called pooled variance;
*/
allele1var=allele1,
allele2var=allele2
);

options compress=no;
/*combine assoc of female and male*/
*Also keep beta but not se, as se can be re-calculated by z/beta;
*SAS OnDemand out of memory if including a.&beta_varname as gwas1_beta,b.&beta_varname as gwas2_beta;
*a.&beta_varname as gwas1_beta,b.&beta_varname as gwas2_beta,;

*Note: ordering by chr and pos in proc sql will consume too much memory and space;

%if %length(&gwas1_tot)>0 and %length(&gwas2_tot)>0 %then %do;
/*use pooled variance: 
sqrt(
(gwas1_tot-1)*se1^2/(total_of_two_gwas-2) + 
(gwas2_tot-1)*se2^2/(total_of_two_gwas-2)
)*/
%let total_d=%sysevalf(&gwas1_tot + &gwas2_tot - 2);
     proc sql;
     create table both as
     select a.&snp_varname,
            a.&beta_varname as gwas1_beta,b.&beta_varname as gwas2_beta,
            a.&se_varname as gwas1_se,b.&se_varname as gwas2_se,
            (a.&beta_varname-b.&beta_varname)/(sqrt(2*(&gwas1_tot-1)*a.&se_varname**2/&total_d+2*(&gwas2_tot-1)*b.&se_varname**2/&total_d)) 
             as diff_zscore,
     	   a.&p_varname as gwas1_P,
            b.&p_varname as gwas2_P,
            a.&beta_varname/a.&se_varname as gwas1_z,
            b.&beta_varname/b.&se_varname as gwas2_z,
            a.&gwas1chr_var as chr,a.&gwas1pos_var as pos
     from (select * from &gwas1dsd(where=(&p_varname<=)) group by &snp_varname having count(&snp_varname)=1) as a,
          (select * from &gwas2dsd group by &snp_varname having count(&snp_varname)=1) as b
     where a.&snp_varname=b.&snp_varname and 
           a.&allele1var=b.&allele1var and a.&allele2var=b.&allele2var
            order by &gwas1chr_var,&gwas1pos_var; 

%end;
%else %do;
     proc sql;
     create table both as
     select a.&snp_varname,
            a.&beta_varname as gwas1_beta,b.&beta_varname as gwas2_beta,
            a.&se_varname as gwas1_se,b.&se_varname as gwas2_se,
            (a.&beta_varname-b.&beta_varname)/(sqrt(a.&se_varname**2+b.&se_varname**2)) as diff_zscore,
     	   a.&p_varname as gwas1_P,
            b.&p_varname as gwas2_P,
            a.&beta_varname/a.&se_varname as gwas1_z,
            b.&beta_varname/b.&se_varname as gwas2_z,
            a.&gwas1chr_var as chr,a.&gwas1pos_var as pos
     from (select * from &gwas1dsd group by &snp_varname having count(&snp_varname)=1) as a,
          (select * from &gwas2dsd group by &snp_varname having count(&snp_varname)=1) as b
     where a.&snp_varname=b.&snp_varname and 
           a.&allele1var=b.&allele1var and a.&allele2var=b.&allele2var
            order by &gwas1chr_var,&gwas1pos_var; 
%end;

/*
*It is better to filter these SNPs in the combined dataset;
*since only SNPs with p<0.01 in any of the two GWAS would be possible for further investigaiton;
data both;
set both;
if gwas1_p<0.5 or gwas2_p<0.5;
run;
*/

*Delete these SNPs with se>1, which should be wrong!;
data both;
set both;
where gwas1_se<=1 and gwas2_se<=1;
run;

*When two gwass are correlated or have a same group as case or control;
*It is necessary to further standardize zscore;
%if &stdize_zscore=1 %then %do;
data both;
set both;
*Keep the unstandized diff-zscore;
Orig_diffzscore=diff_zscore;
run;

%let stdmethod=std;
*IQR can not correct the lambda in the final QQplot;
*Standardize zscore based on std method;
proc stdize data=both method=&stdmethod out=both pstat;
/*    title2 'METHOD=&stdmethod'; */
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

*Need to sort the combined gwas data set again;
/* proc sort data=both;by order by &gwas1chr_var &gwas1pos_var;run; */

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

%if &stdize_zscore=1 %then %do;
   *Perform analysis on original unstandized zscore;
/*    title "GWAS for unstandized differential zscore!"; */
   %zscroe2p(dsdin=both,Zscore_var=Orig_diffzscore,dsdout=both);
   data both;set both;rename Pval=Orig_Pval;run;
%if &mk_manhattan_qqplots4twoGWASs=1 %then %do;
   %print_text_as_title(
   text=%str(GWAS Manhattan and QQ plots for unstandized differential zscore!)
   );
   %manhattan(dsdin=both,
              pos_var=pos,
              chr_var=chr,
              P_var=orig_Pval,
              logP=1,
              dotsize=2,
              gwas_sortedby_numchrpos=0);
   /*proc sort data=Assoc nodupkeys;*/
   /*by &snp_varname;*/
   /*run;*/
   %QQplot(dsdin=both,P_var=Orig_Pval);
   %Lambda_From_P(P_dsd=both,P_var=Orig_Pval,case_n=,control_n=,dsdout=lambdaout);
   title "";
%end;
%end;

*For standardized zscore if the parameter of stdize_zscore=1;
%zscroe2p(dsdin=both,Zscore_var=diff_zscore,dsdout=both);

%if &mk_manhattan_qqplots4twoGWASs=1 %then %do;
%print_text_as_title(
text=%str(GWAS Manhattan and QQ Plots for differential GWAS after standardization!)
);
/* title "GWAS Manhattan Plot for differential GWAS after standardization!"; */
%manhattan(dsdin=both,
           pos_var=pos,
           chr_var=chr,
           P_var=Pval,
           logP=1,
           dotsize=2,
           gwas_sortedby_numchrpos=0);
/*proc sort data=Assoc nodupkeys;*/
/*by &snp_varname;*/
/*run;*/
%QQplot(dsdin=both,P_var=Pval);
%Lambda_From_P(P_dsd=both,P_var=Pval,case_n=,control_n=,dsdout=lambdaout);
title "";
%end;

/*output the dataset both as gwasout*/
proc datasets lib=work nolist;
delete &gwasout;
change both=&gwasout;
run;


%if &mk_manhattan_qqplots4twoGWASs=1 %then %do;
   *Make Manhattan plot and QQplot for each of the two single GWAS;
   %print_text_as_title(
   text=%str(GWAS Manhattan and QQ Plots for &gwas1dsd!)
   );
/*    title "GWAS Manhattan Plot for &gwas1dsd!"; */
   %manhattan(dsdin=&gwas1dsd,
              pos_var=&gwas1pos_var,
              chr_var=&gwas1chr_var,
              P_var=&p_varname,
              logP=1,
              dotsize=2,
              gwas_sortedby_numchrpos=1);
   /*proc sort data=Assoc nodupkeys;*/
   /*by &snp_varname;*/
   /*run;*/
   %QQplot(dsdin=&gwas1dsd,P_var=&p_varname);
   %Lambda_From_P(P_dsd=&gwas1dsd,P_var=&p_varname,case_n=,control_n=,dsdout=lambdaout);
   title "";
   *Make Manhattan plot and QQplot for each of the two single GWAS;
   %print_text_as_title(
   text=%str(GWAS Manhattan and QQ Plots for &gwas2dsd!)
   );
/*    title "GWAS Manhattan Plot for &gwas2dsd!"; */
   %manhattan(dsdin=&gwas2dsd,
              pos_var=&gwas1pos_var,
              chr_var=&gwas1chr_var,
              P_var=&p_varname,
              logP=1,
              dotsize=2,
              gwas_sortedby_numchrpos=1);
   /*proc sort data=Assoc nodupkeys;*/
   /*by &snp_varname;*/
   /*run;*/
   %QQplot(dsdin=&gwas2dsd,P_var=&p_varname);
   %Lambda_From_P(P_dsd=&gwas2dsd,P_var=&p_varname,case_n=,control_n=,dsdout=lambdaout);
   title "";
%end;

%mend;

