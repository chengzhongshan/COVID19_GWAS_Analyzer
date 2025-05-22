%macro mhodds(indata,outdata,level);
/********************************************************/
/* Compute the odds ratio for each study                */
/* (1) Compute Mantel-Haenszel odds ratio and log odds  */
/*     ratio.                                           */
/* (2) Compute the large sample variance estimator based*/
/*     on Robins, Breslow, and Greenland (1986) and     */
/*     Robins, Greenland, and Breslow (1986)            */
/*                                                      */
/* INPUT DATA:                                          */
/*     N11, N12, N21, N22: Cell frequencies for each    */
/*     study.                                           */
/*     LEVEL: Level of confidence for the confidence    */
/*     interval                                         */
/*                                                      */
/* OUTPUT DATA:                                         */
/*     TYPE:    5 = Log of Mantel-Haneszel odds ratio   */
/*                  estimate                            */
/*              6 = Mantel-Haneszel odds ratio estimate */
/*                                                      */
/*     ESTIMATE: Mantel-Haneszel estimate for the given */
/*               type                                   */
/*     LOWER:    Lower bound of confidence interval     */
/*     UPPER:    Upper bound of confidence interval     */
/********************************************************/
data;
   set &indata;
   ntt=n11+n12+n21+n22;
   aa=n11*n22/ntt;
   bb=(n11+n22)/ntt;
   cc=n12*n21/ntt;
   dd=(n12+n21)/ntt;
   ab=aa*bb;
   bc=bb*cc;
   ad=aa*dd;
   cd=cc*dd;
proc means noprint;
   var aa bb cc dd ab bc ad cd;
   output out=&outdata
          sum=saa sbb scc sdd sab sbc sad scd;
data &outdata;
   set &outdata;
   type=6;
   estimate=saa/scc;
   level=&level;
   variance=(sab+(saa/scc)*(sbc+sad+(saa/scc)*scd))
            /(2*saa*saa);
   lower=estimate+probit(.5-.5*level)*sqrt(variance);
   upper=estimate+probit(.5+.5*level)*sqrt(variance);
   output;
   type=5;
   estimate=log(saa/scc);
   lower=log(lower);
   upper=log(upper);
   variance=.;
   output;
   keep type estimate level variance lower upper;
%mend mhodds;
