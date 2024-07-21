%macro randombetween(min, max);
   %local rnd min max diff;
   %let rnd=%sysfunc(rand(uniform));
   %let diff=%sysfunc(floor(%sysevalf((1+&max-&min))*&rnd));
   %let rnd=%sysevalf(&diff+&min);
   &rnd
%mend;
/*Demo:
options mprint mlogic symbolgen;
%let randnum=%randombetween(1,1000);
*/
