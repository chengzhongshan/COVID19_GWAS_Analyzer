%macro QQplot(dsdin,P_var);
proc sql noprint;
select count(*) into: tot
from &dsdin;

data &dsdin;
set &dsdin;
where &P_var>0;

*sort and exclude these missing P values;
proc sort data=&dsdin;
by &P_var;
run;

data dataout;
set &dsdin;
retain x_;
gap=1/&tot;
ini=gap/2;
if _n_=1 then x_=ini;
else x_=x_+gap;
x=-log10(x_);
y=-log10(&P_var);
run;


proc sql noprint;
select ceil(max(y)) into: max_y
from dataout;

*Adjust the tick number when the &max_y>10;
%let step=1;
%if &max_y>=20 %then %do;
  %let step=5;
  *Update the max_y can be divided by 5;
  %let max_y=%sysevalf(%sysevalf(&max_y/5,ceil)*5);
%end;

/*make sure to put reset here*/
/*otherwise symbol2 will not work*/
goptions reset=global hsize=15cm vsize=15cm;
symbol1 interpol=none value=dot color=maroon;
symbol2 interpol=rl value=none color=black;
%let fontsize=3;
axis1 label=(f='arial' h=&fontsize 'Expected -log10(P)' justify=c)
      order=(0 to &max_y by &step) value=(f='arial' h=&fontsize);
axis2 label=(a=90 f='arial' h=&fontsize 'Observed -log10(P)')
      order=(0 to &max_y by &step) value=(f='arial' h=&fontsize);
proc gplot data=dataout;
plot y*x x*x/overlay 
           haxis=axis1
           vaxis=axis2
           noframe;
run;

*Also make a QQ plot with x- and y-axis with the same scale and maximum value of 8;
goptions reset=global hsize=15cm vsize=15cm;
symbol1 interpol=none value=dot color=maroon;
symbol2 interpol=rl value=none color=black;
%let fontsize=3;
axis1 label=(f='arial' h=&fontsize 'Expected -log10(P)' justify=c)
      order=(0 to 8 by 1) value=(f='arial' h=&fontsize);
axis2 label=(a=90 f='arial' h=&fontsize 'Observed -log10(P)')
      order=(0 to 8 by 1) value=(f='arial' h=&fontsize);
proc gplot data=dataout;
plot y*x x*x/overlay 
           haxis=axis1
           vaxis=axis2
           noframe;
run;

%mend;
/*

%QQplot(dsdin=sasuser.assoc,P_var=P);

*/
