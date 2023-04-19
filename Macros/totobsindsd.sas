%macro totobsindsd(mydata);
    %let mydataID=%sysfunc(OPEN(&mydata.,IN));
    %let NOBS=%sysfunc(ATTRN(&mydataID,NOBS));
    %let RC=%sysfunc(CLOSE(&mydataID));
    &NOBS
%mend;

/*Demo:
%let nobs=%totobsindsd(sashelp.cars);
%put The total number of observations in the dataset is &nobs;
*/
