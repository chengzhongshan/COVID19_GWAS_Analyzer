%macro randombetween(min, max);
   %let rnd=%sysfunc(rand(uniform));
   %let diff=%sysfunc(floor(%sysevalf((1+&max-&min))*&rnd));
   %let rnd=%sysevalf(&diff+&min);
   %put Your random number generated between &min and &max is &rnd;
   &rnd
%mend;
/*Demo:
options mprint mlogic symbolgen;
%let randnum=%randombetween(1,1000);
*/
