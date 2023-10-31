%macro totobsindsd(mydata);
    %let mydataID=%sysfunc(OPEN(&mydata.,IN));
    %let NOBS=%sysfunc(ATTRN(&mydataID,NOBS));
    %let RC=%sysfunc(CLOSE(&mydataID));
    %if "&NOBS"^="." %then %do;
      &NOBS
    %end;
    %else %do;
       0
    %end;
%mend;

/*Demo:
%let nobs=%totobsindsd(sashelp.cars);
%put The total number of observations in the dataset is &nobs;
*/
