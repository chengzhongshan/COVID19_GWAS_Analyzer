
%macro RandBetween(min, max);
%local min max rnd _unif_num_ _rnd_;
%let _unif_num_=%sysfunc(ranuni(0));
%let _rnd_=%sysevalf((1+&max-&min)*&_unif_num_);
%let rnd=%sysfunc(floor(&_rnd_));
&rnd
%mend;


/*Demo codes:;
*Note: rand('norma') does not work when using the macro by other macro!;
*So the macro has been updated to use ranuni(0);

%let rnd=%RandBetween(1,100);
%put &rnd;

*Use it for ods graphic to generate random number for the appendix of output figures;
ods graphics on / imagename="Figure_&rnd";
%print_head4dsd(dsdin=sashelp.cars,n=10);
proc sgplot data=sashelp.cars;
scatter x=EngineSize y=Cylinders/group=Type;
run;
%put %sysfunc(getoption(work));

*Alternative way to generate random number;

%sysfunc(floor(%sysfunc(ranuni(0,1,1000))))

*/

/*%macro RandBetween(min, max);*/
/*%local min max rnd;*/
/*%let rnd=%trim(%left(%sysevalf (&min + %sysfunc(floor(%sysevalf((1+&max-&min)*%sysfunc(rand(uniform))))))));*/
/*&rnd*/
/*%mend;*/
/**The above macro will crash SAS without unknown reason!;*/


