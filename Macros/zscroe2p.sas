%macro zscroe2p(dsdin,Zscore_var,dsdout);
data &dsdout;
set &dsdin;
pval= probnorm(&Zscore_var);
/*pval=cdf('normal',&Zscore_var);*/
if (pval > .5)  then pval= 1 - pval;
pval= 2*pval;
*SAS only can obtain pval no more less than 1e-16;
if pval=0 then pval=1e-16;
run;
%mend;

/*
%zscroe2p(dsdin=both,Zscore_var=diff_zscore,dsdout=both_zscore);
*/


