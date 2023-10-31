%macro import_plink_ped(
pedfile=,
out=x
);
proc import datafile="&pedfile" dbms=dlm out=x replace;
getnames=no;
delimiter=' ';
guessingrows=10000;
run;
%mend;
