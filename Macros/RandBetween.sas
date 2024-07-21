%macro RandBetween(min, max);
%local min max rnd;
%let rnd=%trim(%left(%sysevalf (&min + %sysfunc(floor(%sysevalf((1+&max-&min)*%sysfunc(rand(uniform))))))));
&rnd
%mend;

/*%macro RandBetween(min, max);*/
/*   (&min + floor((1+&max-&min)*rand("uniform")))*/
/*%mend;*/


/*Demo codes:;
%let rnd=%RandBetween(1,100);
%put &rnd;

*Use it for ods graphic to generate random number for the appendix of output figures;
ods graphics on / imagename="Figure_%RandBetween(1,100)";
%print_head4dsd(dsdin=sashelp.cars,n=10);
proc sgplot data=sashelp.cars;
scatter x=EngineSize y=Cylinders/group=Type;
run;
%put %sysfunc(getoption(work));

*/

