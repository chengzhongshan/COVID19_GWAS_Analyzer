%macro assign_str4missing(Inval,NewVal);
%let Updated_Val=;
%if %eval("&Inval"="") %then %do;
 %put New value &NewVal is updated for your input string "&Inval";
 %let Updated_Val=&NewVal;
 &NewVal
%end;
%else %do;
 &Inval
%end;
 
%mend;

/*Use it in macro ONLY;

%let X=%assign_str4missing(Inval=,NewVal=XXXX);

*/

