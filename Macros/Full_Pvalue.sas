%macro Full_Pvalue(dsdin,dsdout);
proc contents data=&dsdin noprint out=P_tmp;
run;

proc sql noprint;
select count(*) into: Ptot
from P_tmp 
where prxmatch('/PVALUE/',FORMAT);

select NAME into: v1-:%sysfunc(catx(%str(),v,&Ptot)) 
from P_tmp
where prxmatch('/PVALUE/',FORMAT);

%put &&v1;

%if &Ptot>0 %then %do;
 data &dsdout;
 set &dsdin;
 attrib %do i=1 %to &Ptot;
        &&v&i format=best32. 
		%end;
 ;
 run;
%end;

%mend;

/*

options mprint mlogic symbolgen spool;
%Full_Pvalue(dsdin=Modelanova1,dsdout=x);

*/
