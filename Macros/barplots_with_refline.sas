
%macro barplots_with_refline(dsdin,yaxis_var);
/*The following script will draw bar plot for your dataset a*/

proc sort data=&dsdin;by &yaxis_var;
data &dsdin;
set &dsdin;
grp=_n_;

/*stderr is not used in the graph, but I just don't want to change my old code*/
proc means data=&dsdin noprint;
by grp;
var &yaxis_var;
output out=mean mean=mean stderr=stderr;
run;
data mean;
set mean;
stderr=0;
up=mean+stderr;
down=mean-stderr;
keep grp mean up down stderr;
run;
proc sql noprint;
select min(mean-stderr-0.1) into:minval from mean;
select max(mean+stderr+0.1) into:maxval from mean;
quit;

proc sort data=mean;by grp;run;
data ANNO1;
length function style color $8 text $50;
set mean;
%annomac;

if mean<0 then do;
%system(2,2);
function='move';midpoint=grp;y=mean-stderr;output;
%system(7,7);
function='move';x=-0.1;y=0;output;
function='draw';x=0.1;y=0;color='white';output;/*Draw errorbars in white, as no need them here*/
function='move';x=-0.1;y=0;output;
%system(7,2);
function='draw';x=0;y=mean;color='red';output;
end;
else do;
%system(2,2);
function='move';midpoint=grp;y=mean+stderr;output;
%system(7,7);
function='move';x=-0.1;y=0;output;
function='draw';x=0.1;y=0;color='white';output;
function='move';x=-0.1;y=0;output;
%system(7,2);
function='draw';x=0;y=mean;color='red';output;
end;

run;
proc sql ;
select ceil(max(&yaxis_var)+max(&yaxis_var)*0.1), floor(min(&yaxis_var)-min(&yaxis_var)*0.1), round(max(&yaxis_var)-min(&yaxis_var))/10 into: 
       max_yaxis_var, :min_yaxis_var, :y_num_ticks
from &dsdin;

proc sql;
select count(*) into: tot
from &dsdin;

/*change y-axis limit according to your WT VAR range*/
/*modify it for better borplot*/
axis1 order=(&min_yaxis_var to &max_yaxis_var by -&y_num_ticks) label=(f=arial h=2 a=90 "WT Variation (%)") value=(f=Arial h=2) major=(h=2) width=2;

/*reverse the order of x-axis*/
axis2 order=(&tot to 0 by -1) value=none label=none width=2;

axis3 label=none value=none offset=(5,5);
pattern1 v=s c=grey;/*change bar color here*/
pattern2 v=s c=black;
legend1 shape=bar(5,2)CELLS label=none position=(top center inside)
mode=protect value=(j=left h=2 font=arial);
proc gchart data=mean gout=graf;
vbar grp / discrete
sumvar=mean
width=5
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


/*Demo:

%barplots_with_refline(dsdin=a,yaxis_var=VR);

*/
