%macro wavgodds(indata,outdata,intype,level);
/********************************************************/
/*  INDATA: The output data set from SAS MACRO COMPODDS */
/*  INTYPE: Type of log odds ratio to be combined       */
/*    INTYPE = 1 for combining log odds ratio           */
/*    INTYPE = 3 for combining amended log              */
/*         odds ratio because some studies have zero    */
/*         frequencies in one or more cells             */
/*  LEVEL: Level of confidence for the confidence       */
/*         interval of the combined weighted average    */
/*                                                      */
/*  OUTDATA:                                            */
/*      The output data file contains five variables.   */
/*                                                      */
/*      (1) TYPE: The type of effect size               */
/*          TYPE can have value 1 (log odds ratio) and  */
/*          2 (odds ratio) if INTYPE = 1.               */
/*          TYPE can have value 3 (amended log odds     */
/*          ratio) and 4 (amended odds ratio) if        */
/*          INTYPE = 3.                                 */
/*      (2) ESTIMATE:  Combined estimate for the        */
/*          given effect size TYPE.                     */
/*      (3) LOWER: Lower bound for confidence interval  */
/*      (4) UPPER: Upper bound for confidence interval  */
/*      (5) LEVEL: Level of confidence for the          */
/*      confidence interval.                            */
/********************************************************/
data;
   set &indata;
   if type = &intype;
   weight = 1 / variance;
   wlodds = estimate * weight;
   keep wlodds weight;
proc means noprint;
   var wlodds weight;
   output out = &outdata sum=swlodds sweight;
data &outdata;
   set &outdata;
   type = &intype;
   estimate = swlodds / sweight;
   level=&level;
   variance = 1 / sweight;
   lower = estimate + probit(.5-.5*&level) * sqrt(variance);
   upper = estimate + probit(.5+.5*&level) * sqrt(variance);
   output;
   type = &intype+1;
   estimate = exp(estimate);
   lower = exp(lower);
   upper = exp(upper);
   output;
   keep type estimate level lower upper;
%mend wavgodds;
