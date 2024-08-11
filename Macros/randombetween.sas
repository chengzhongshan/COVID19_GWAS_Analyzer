%macro randombetween(min, max);
   %local rnd min max diff;
   %let rnd=%sysfunc(ranuni(0));
   %let diff=%sysfunc(floor(%sysevalf((1+&max-&min))*&rnd));
   %let rnd=%sysevalf(&diff+&min);
   &rnd
%mend;
/*Demo:

*Note: rand('norma') does not work when using the macro by other macro!;
*So the macro has been updated to use ranuni(0);

options mprint mlogic symbolgen;
%let randnum=%randombetween(1,1000);

*Alternative way to generate random number;

%sysfunc(floor(%sysfunc(ranuni(0,1,1000))))

*/
