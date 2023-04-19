%macro Sampling(indsd,n,nperm,dsdout);
options nonotes compress=yes;
%let i=1;
%do %while(&i<=&nperm);
proc surveyselect data=&indsd
   method=srs n=&n out=&dsdout.s&i noprint;
run;
data &dsdout.s&i;
set &dsdout.s&i;
gp_perm=&i;
run;

%if &i=1 %then %do;
data &dsdout;
set &dsdout.s&i;
run;
%end;
%else %do;
data &dsdout;
set &dsdout &dsdout.s&i;
run;
%end;
%let i=%eval(&i+1);
%end;
proc datasets lib=work nolist;
delete &dsdout.s:;
run;
options notes compress=no;
%put Finish samples &nperm times;
%mend;

/*

*It will creat new group variable gp_perm and number it from 1 to nperm;
%Sampling(indsd=nondrivers,n=100,nperm=10,dsdout=x);

*/
