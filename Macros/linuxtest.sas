%macro linuxtest;
proc print data=sashelp.cars(obs=20);
run;
%mend;
