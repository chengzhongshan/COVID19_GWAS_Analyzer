%macro mkfmt4grps_by_var(
grpdsd,
grp_var,
by_var,/*Empty value is possible for this var, which is handy 
when there would be duplciates of grp_var after sorting by 
grp_var and by_var for the by_var to make a new format*/
outfmt4numgrps,
outfmt4chargrps
);
%local rnd;

proc sort data=&grpdsd(keep=&grp_var &by_var) nodupkeys out=grpdsd;
*Make sure to sort it first by &by_var, and then by &grp_var;
*This was wrong, as some grps will be excluded by nodupkeys sorting with &by_var first;
by &grp_var &by_var;
run;

proc sql noprint;
select max(ndup_grps) into: maxdups
from 
(select count(*) as ndup_grps
from grpdsd
group by &grp_var)
;

%if &maxdups >1 %then %do;
		   %put Please evaluate the data set grpdsd for the combination between two vars, including &grp_var and &by_var;
		   %put It is necessary to have no duplicates in the first grp_var: &grp_var;
		   %put Currently there are duplicates for grp_var &grp_var after running proc sort nodupkeys by the two vars;
		   %put You may try to replace the two vars by using grp_var and grp_var, which means to use grp_var to replace the by_var;
		   %abort 255;
%end;

*The above dataset may still contains duplicates of &grp_var;
*Need to keep all unique &by_var and &grp_var;
/* proc sort data=grpdsd nodupkeys;by &grp_var; */
/* proc sort data=grpdsd;by &by_var &grp_var; */
/* run; */

*Need to sort grps by the by_var for making formats;
*Only when the by_var is not empty, run this codes;
%if %length(&by_var)>0 %then %do;
proc sort data=grpdsd;by &by_var;run;
%end;

%let rnd=%randombetween(100,200);
%let rnd=&rnd._;
data fmt4numgrps&rnd;
set grpdsd;
fmtname = "&outfmt4numgrps";
type = "I";
label = _N_;
rename &grp_var = start;
run;
proc format cntlin=fmt4numgrps&rnd;
run;
quit;
data fmt4chargrps&rnd;
set grpdsd(drop=&by_var);
*Do not use &by_var here to asign group specific order for start;
*This will be a bug when there are duplicates in the &by_var;
/* by &by_var; */
start = _N_;
rename &grp_var=label;
fmtname = "&outfmt4chargrps";
type = "n";
run;
proc format cntlin=fmt4chargrps&rnd;
run;

%mend;

/*Demo:
data g;
input x $ y;
cards;
a 1
d 2
c 3
b 4
e 5
;
data x;
input a $ b c;
cards;
a 10 1
b 40 2
c 100 3
d 10 4
e 40 5
a 10 1
b 50 2
c 100 3
d 10 4
e 40 5
;

proc sgpanel data=x;
panelby a/rows=1 onepanel novarname;
scatter x=b y=c;
run;

*apply format to sort panel by a;
%mkfmt4grps_by_var(
grpdsd=g,
grp_var=x,
by_var=y,
outfmt4numgrps=x2y,
outfmt4chargrps=y2x
);
data x1;
set x;
*format char grps to numeric grps;
new_a=input(a,x2y.);

proc sgpanel data=x1;
*format back numeric grps back to characters;
format new_a y2x.;
panelby new_a/rows=1 onepanel novarname;
scatter x=b y=c;
run;

*Need to use the format y2x. for new_a within the proc sgplot procedure;
*Can format new_a in a dataset, and then apply the proc sgplot;
*Which will generate mixed axis labels with numbers and chars;

proc sgplot data=x1;
format new_a y2x.;
heatmapparm x=b y=new_a colorresponse=c/outline outlineattrs=(color=white thickness=4 pattern=solid)
                                         colormodel=(blue green red);
run;

*Format the var first, and then use the heatmap macro;
data x2;
set x1;
attrib new_a format=y2x.;
run;

%heatmap4longformatdsd(
dsdin=x2,
xvar=b,
yvar=new_a,
colorvar=c,
fig_height=400,
fig_width=400,
outline_thickness=4
);


*/


