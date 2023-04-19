%macro tabulate4bins(dsd,byids,target_var4bin,bins,dsdout);
%let ncutoffs=%numargs(&bins);
/*change byids for proc sql;*/
%let _byids_=%sysfunc(prxchange(s/\s+/%str(,)/,-1,&byids));
%let i=1;
%let bin=%scan(&bins,&i,%str(' '));
%let i=2;
%let format_string=%sysfunc(cat(low-,&bin)) = "low>=&bin";
%put &format_string;
%do %while (%scan(&bins,&i,%str(' ')) ne );
   %let lagbin=%scan(&bins,%eval(&i-1),%str(' '));
   %let bin=%scan(&bins,&i,%str(' '));
   %let tmp_bin=%sysfunc(cat(&lagbin,-,&bin)) = "&lagbin-&bin";
   %let format_string=&format_string &tmp_bin;
 %let i=%eval(&i+1);
%end;
%put &format_string;

proc format;
value frt &format_string
			other='unknown';

ods select none;
ods output OneWayFreqs=&dsdout;
proc sort data=&dsd;by &byids;
proc freq data=&dsd;
table &target_var4bin;
format &target_var4bin frt.;
by &byids;
run;
ods select all;

%mend;
/*
options mprint mlogic symbolgen;
*pay attention to olds select none in the macro;
%tabulate4bins(dsd=SNPs,byids=g memname,target_var4bin=delta,bins=10 20 30 40 50 60 70 80 90 100,dsdout=all);
*/
