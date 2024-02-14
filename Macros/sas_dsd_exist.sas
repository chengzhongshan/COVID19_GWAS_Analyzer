%macro sas_dsd_exist(sasdsd,lib=work);
%local sas_dt_exist;
%let sas_dt_exist=0;
%if %sysfunc(prxmatch(/\./,&sasdsd)) %then %do;
   %let lib=%scan(&sasdsd,1,.);
   %let sasdsd=%scan(&sasdsd,2,.);
%end;
%let sas_dt_exist=%sysfunc(exist(&lib..&sasdsd));
&sas_dt_exist
%mend;
/*Demo codes:;
*This macro is a sas function to check the existence of a sas dataset;

%let test=%sas_dsd_exist(sasdsd=gwas1,lib=D);
%put &test;

%let test=%sas_dsd_exist(sasdsd=D.gwas1x);
%put &test;


*/



