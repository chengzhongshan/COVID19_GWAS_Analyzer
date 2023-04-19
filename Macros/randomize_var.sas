%macro randomize_var(dsdin,var,rand_fun,dsdout);
proc sql noprint;
select count(*) into: totn
from &dsdin;
data &dsdout;
set &dsdin;
call streaminit(123);
xrnd=rand("&rand_fun",1,&totn);
ord=_n_;
proc sort data=&dsdout;by xrnd;
data &dsdout;
set &dsdout;
rnd_ord=_n_;
run;
proc sort data=&dsdout out=_tmp_;by ord;
data &dsdout(drop=xrnd ord rnd_ord);
set &dsdout(rename=(&var=old_&var));
set _tmp_(keep=&var);
run;
/*proc print;run;*/
%mend;

/*Demo:
data a;
input exp;
cards;
1
2
3
4
;
%randomize_var(
dsdin=a,
var=exp,
rand_fun=uniform,
dsdout=x
);

*/
