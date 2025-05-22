*options nodate nocenter pagesize=54 linesize=80 pageno=1;
%macro homeodds(indata,outdata,type,initial);
data; set &indata;
/*******************************************************/
/* Compute the chi-square test statistics for the      */
/* homogeneity of common odds ratio based on Breslow   */
/* and Day (1980)                                      */
/*                                                     */
/* INPUT DATA:                                         */
/*   Cell frequencies for each study:                  */
/*      N11, N12, N21, and N22.                        */
/*                                                     */
/* OUTPUT DATA:                                        */
/*   The chi-square test statistics with k-1 degrees of*/
/*   freedom, where k is the number of studies in the  */
/*   meta-analysis.                                    */
/*                                                     */
/* TYPE:                                               */
/*   TYPE=2 if no studies have zero cell frequencies   */
/*   TYPE=4 if some studies have zero cell frequencies */
/*                                                     */
/* INITIAL:                                            */
/*   Initial value to start the Newton iteration.  The */
/*   weighted average common odds ratio can be used as */
/*   the initial value.                                */
/*******************************************************/
   if (&type=4) then do;
      n11=n11+.5;
      n12=n12+.5;
      n21=n21+.5;
      n22=n22+.5;
   end;
   oddmle=&initial;
   df = 1;
   m1=n11+n22;
   m2=n12+n21;
   xold=n11;
   xnew=(n11+n12)*(n11+n21)/(n11+n12+n21+n22);
/*******************************************************/
/*   Estimate the cell frequencies based on the Newton */
/*   method                                            */
/*******************************************************/
   do until (abs(xold-xnew) < .1e-5);
      xold = xnew;
      fold = ((1-oddmle)*xnew-(m1+oddmle*m2))*xnew
             +(n11*n22-n12*n21*oddmle);
      pfold = 2*(1-oddmle)*xnew-(m1+oddmle*m2);
      xnew = xold - fold / pfold;
   end;
   varstat=1/(1/(n11-xnew)+1/(n12+xnew)+1/(n21+xnew)+1/(n22-xnew));
   chisq = (xnew*xnew)/varstat;
   keep df chisq;
proc means noprint;
   var df chisq;
   output out=&outdata sum = df chisq;
data &outdata;
   set &outdata;
   df = df -1;
   pvalue = 1-probchi(chisq,df);
   keep df chisq pvalue;
run;
%mend homeodds;
