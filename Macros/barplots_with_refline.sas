
%macro barplots_with_refline(
dsdin,
yaxis_var,
errorbar_length=1,
bar_width=5,
errorbar_color=blue,
bar_color=lightblue,
grp_var=,
sort_bar_var_by_mean=1,/*If value is 0, it will sort by grp_var alphabetically*/
yaxis_label=Mean of target variable
);
/*The following script will draw bar plot for your dataset*/


proc sort data=_dsdin_;by &yaxis_var;
data _dsdin_;
set &dsdin;
%if %length(&grp_var)>0 %then %do;
 grp=&grp_var;
%end;
%else %do;
 grp=_n_;
%end;

/*stderr is not used in the graph, but I just don't want to change my old code*/
proc means data=_dsdin_ noprint;
by grp;
var &yaxis_var;
output out=mean mean=mean stderr=stderr;
run;
data mean;
set mean;

*Exclude stderr if necessary;
/*stderr=0;*/

up=mean+stderr;
down=mean-stderr;
keep grp mean up down stderr;
run;
proc sql noprint;
select min(mean-stderr-0.1) into:minval from mean;
select max(mean+stderr+0.1) into:maxval from mean;
quit;

proc sort data=mean;
%if &sort_bar_var_by_mean=1 %then %do;
   by mean;
%end;
%else %do;
  by grp;
%end;
run;
data mean;
set mean;
*Use numeric order to draw barplots;
_grp_=_n_;
run;

data ANNO1;
length function style color $8 text $50;
set mean;
%annomac;

if mean<0 then do;
%system(2,2);
function='move';midpoint=_grp_;y=mean-stderr;output;
%system(7,7);
function='move';x=-&errorbar_length;y=0;output;
function='draw';x=%sysevalf(&errorbar_length*2);y=0;color="&errorbar_color";output;/*Draw errorbars in white, as no need them here*/
function='move';x=-&errorbar_length;y=0;output;
%system(7,2);
function='draw';x=0;y=mean;color="&errorbar_color";output;
end;
else do;
%system(2,2);
function='move';midpoint=_grp_;y=mean+stderr;output;
%system(7,7);
function='move';x=-&errorbar_length;y=0;output;
function='draw';x=%sysevalf(&errorbar_length*2);y=0;color="&errorbar_color";output;
function='move';x=-&errorbar_length;y=0;output;
%system(7,2);
function='draw';x=0;y=mean;color="&errorbar_color";output;
end;

run;
proc sql ;
select ceil(max(&yaxis_var)+max(&yaxis_var)*0.1), floor(min(&yaxis_var)-min(&yaxis_var)*0.1), round(max(&yaxis_var)-min(&yaxis_var))/10 into: 
       max_yaxis_var, :min_yaxis_var, :y_num_ticks
from _dsdin_;

proc sql;
select count(*) into: tot
from mean;
select quote(grp) into: grp_list separated by " "
from mean 
order by _grp_;

/*change y-axis limit according to your WT VAR range*/
/*modify it for better borplot*/
axis1 order=(&min_yaxis_var to &max_yaxis_var by -&y_num_ticks) label=(f=arial h=2 a=90 "&yaxis_label") value=(f=Arial h=2) major=(h=2) width=2;

/*reverse the order of x-axis*/
/*axis2 order=(&tot to 0 by -1) value=none label=none width=2;*/
/*axis2 value=none label=none width=2;*/

*Customize your xaxis;
*https://support.sas.com/resources/papers/proceedings-archive/SUGI95/Sugi-95-134%20Carpenter.pdf;
%if &tot<100 %then %do;
axis2 value=(angle=45 &grp_list ) label=none width=2;
%end;
%else %do;
axis2 value=none label=none width=2;;
%end;

axis3 label=none value=none offset=(5,5);
pattern1 v=s c=&bar_color;/*change bar color here*/
pattern2 v=s c=&bar_color; /*Make the box outline in the same color as that of bar color*/
legend1 shape=bar(5,2)CELLS label=none position=(top center inside)
mode=protect value=(j=left h=2 font=arial);

proc gchart data=mean gout=graf;
vbar _grp_ / discrete
sumvar=mean
width=&bar_width
type=mean
raxis=axis1
maxis=axis2
gaxis=axis3
levels=all
legend=legend1 /*assign legends for the above patterns*/
nofr
annotate=anno1
;
run;
quit;

%mend;


/*Demo codes:;

%barplots_with_refline(dsdin=a,yaxis_var=VR);

%barplots_with_refline(dsdin=sashelp.cars,yaxis_var=MPG_City,grp_var=make);

*/
