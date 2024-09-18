%macro print_head4dsd(dsdin,n=10);
 %if &dsdin eq %then %do;
   %let dsdin=_last_;
			%put Use the last sas dataset &dsdin for printing;
	%end;

 %let dsid=%sysfunc(open(&dsdin,I));
	%let nobs=%sysfunc(attrn(&dsid,nobs));
	%let rc=%sysfunc(close(&dsid));
	proc print data=&dsdin (obs=&n);
	title "First &n obs of &dsdin. Total Obs: &nobs";
	run;
title;

%mend;

/*Demo:

data x;
set sashelp.cars;
run;
%print_head4dsd;
%print_head4dsd(n=100);

%print_head4dsd(sashelp.cars);

%print_head4dsd(dsdin=sashelp.cars,n=100);

*/

