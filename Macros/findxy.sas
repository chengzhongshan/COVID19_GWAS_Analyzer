%macro findxy(dataname,xx,yy);
proc univariate data=&dataname noprint;
   var &xx &yy;
   output out=outa min = minxx minyy max = maxxx maxyy;
proc print data=outa;
run;
%mend findxy;
