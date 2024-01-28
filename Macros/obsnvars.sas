%macro obsnvars(ds= /*This macro will only print out message to indicate the number of records in a dataset!*/);
   %global dset nvars nobs;
   %let dset=&ds;
   %let dsid = %sysfunc(open(&dset));
   %if &dsid %then
      %do;
         %let nobs =%sysfunc(attrn(&dsid,NOBS));
         %let nvars=%sysfunc(attrn(&dsid,NVARS));
         %let rc = %sysfunc(close(&dsid));
         %put &dset has &nvars  variable(s) and &nobs observation(s).;
      %end;
   %else
      %put Open for data set &dset failed - %sysfunc(sysmsg());
%mend obsnvars;

/*%obsnvars(sashelp.cars);*/
