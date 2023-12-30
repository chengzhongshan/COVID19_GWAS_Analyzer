%macro findxy(dataname,xx,yy,outdsd=outa);
proc univariate data=&dataname noprint;
   var &xx &yy;
   output out=&outdsd min = minxx minyy max = maxxx maxyy;
proc print data=&outdsd;
run;
%mend findxy;


