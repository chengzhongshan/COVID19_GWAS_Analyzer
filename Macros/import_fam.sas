%macro import_fam(file,out);
proc import datafile="&file"
dbms=dlm out=&out replace;
delimiter=' ';
getnames=no;
guessingrows=2000;
run;
%mend;
