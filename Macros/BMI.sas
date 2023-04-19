%macro BMI(WgtPd_Var,HgtIN_Var);
%if &HgtIN_var= or &WgtPd_var= %then %do;
    .
%end;
%else %do;
&WgtPd_var*0.45/(&HgtIN_Var*0.025)**2
%end;
%mend;

/*
options mprint mlogic symbolgen;
data a;
input Wgt Hgt;
BMI=%BMI(Wgt,Hgt);
cards;
125 63
;
run;

data b;
set a;
x=%BMI(Wgt,Hgt);
run;

*/
