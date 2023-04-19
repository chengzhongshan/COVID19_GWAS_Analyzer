
%macro Lambda_From_P(P_dsd,P_var,case_n,control_n,dsdout);
data tmp;
set &P_dsd(where=(&P_var>0));
chisq=cinv(1-&P_var,1);
run;

proc sql;
create table &dsdout as
select median(chisq)/cinv(0.5,1) as lamdba
     %if (&case_n ne and &control_n ne) %then %do;
	 ,
     1+(median(chisq)/cinv(0.5,1)-1)*(1/&case_n+1/&control_n)*500 as lambda1000
     %end;
from tmp;

proc datasets lib=work nolist;
delete tmp;
run;
title "Please find your lambda in sas dataset &dsdout:";
proc print data=&dsdout;
run;
%mend;

/*

%Import_Space_Separated_File(abs_filename=E:\Yale_GWAS\ALL_GWGO_HCE_AA_combined_meta.txt,
                             firstobs=1,
							 getnames=yes,
                             outdsd=Assoc);

%Lambda_From_P(P_dsd=Assoc,P_var=P,case_n=,control_n=,dsdout=OUT);

*/
