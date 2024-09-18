%macro TotVarsInDsd(/*This macro is able to count all, numeric, or character vars in a sas dataset*/
ds, /*This macro return total number of variables in a dsd*/
var_type=_all_ /*optional values including _all_, _numeric_, or _character_ 
for counting total number of all, numeric, or character vars*/
);
   
   %local dset dsid;
   %let dset=&ds;
   %let dsid = %sysfunc(open(&dset(keep=&var_type)));
   %if &dsid %then
      %do;
/*         %let nobs =%sysfunc(attrn(&dsid,NOBS));*/
         %let nvars=%sysfunc(attrn(&dsid,NVARS));
         %let rc = %sysfunc(close(&dsid));
          &nvars
      %end;

%mend;

/*Demo codes:;

%let nvars=%TotVarsInDsd(sashelp.cars,var_type=_character_);
%put &nvars;

*/
