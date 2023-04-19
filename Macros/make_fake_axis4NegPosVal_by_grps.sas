%macro make_fake_axis4NegPosVal_by_grps(
dsdin,
axis_var,/*Both negative and positive values of axis var are allowed to use this macro,
           but in each group, only positve (>0) or negative (<0) values are allowed,
           and all 0 axis var values will be excluded from the dsdin, 
           the above of which are the limitations of the macro!*/
axis_grp,
new_fake_axis_var,
dsdout,
yaxis_macro_labels=ylabelsmacro_var,
fc2scale_pos_vals=1 /*Use this fc to enlarge the proportion of positive values in the plots
               It seems that fc=2 is the best for the final ticks of different tracks;*/
);

*This para is important for making correct fake axis;
%let axis_step=1;
************************************************************************;
*Get records with negative values in &dsdin;
data &dsdin._neg;
set &dsdin (where=(&axis_var<0));
*temporarily make all negative axis_var as positve ones;
&axis_var=&axis_var*-1;
run;

%if %totobsindsd(&dsdin._neg)=0 %then %do;
  %put There are NO negative values in the dsd &dsdin._neg;
  %abort 255;
%end;

*Make fake_axis for the dsd &dsdin._pos;
%add_fake_pos_by_grp4nonnegvars(
dsdin=&dsdin._neg,
axis_var=&axis_var,
axis_grp=&axis_grp,
new_fake_axis_var=&new_fake_axis_var,
dsdout=&dsdin._neg_fk,
axis_step=&axis_step
);

*change back all newly created vars into negative ones;
*including mid_val, tpos, &axis_var, fake&axis_grp, and grp_n;
data &dsdin._neg_fk;set &dsdin._neg_fk;
mid_val=mid_val*-1;grp_n=-1*grp_n;
tpos=tpos*-1;&axis_var=&axis_var*-1;
&new_fake_axis_var=&new_fake_axis_var*-1;
n=n*-1;grpnum=-1*grpnum;
run;

************************************************************************;
*Get records with postive values in &dsdin;
data &dsdin._pos;
*Here would be a potential bug if 0 is the top value in a group with all negative values;
*However, for gene track and scatterplot, this is unlikely happen, as the scatterplot;
*usually has all positive values, including 0;
set &dsdin (where=(&axis_var>=0));
*set &dsdin (where=(&axis_var>0));
*Scale position value and make it larger by fold change;
&axis_var=&fc2scale_pos_vals*&axis_var;
run;

%if %totobsindsd(&dsdin._pos)=0 %then %do;
  %put There are NO positive values in the dsd &dsdin._pos;
  %abort 255;
%end;

*Make fake_axis for the dsd &dsdin._pos;
%add_fake_pos_by_grp4nonnegvars(
dsdin=&dsdin._pos,
axis_var=&axis_var,
axis_grp=&axis_grp,
new_fake_axis_var=&new_fake_axis_var,
dsdout=&dsdin._pos_fk,
axis_step=&axis_step
);

******************Combine fake negative and positve dsds****************;
data &dsdout;
*Note: put the neg dsd first;
set &dsdin._neg_fk &dsdin._pos_fk;
grp_end_tag=tag;
run;

************************************************************************;
*Generate real y axis labels;
%global &yaxis_macro_labels fake_max_y fake_min_y fake_refline_values;

*focus on negative axis values first;
data &dsdin._neg_fk;
set &dsdin._neg_fk;
max_neg=0;
run;
proc sql noprint;
select floor(&axis_var),max_neg
into: min_neg_y4grps separated by " ",
    : max_neg_y4grps separated by " "
from &dsdin._neg_fk
where tag=1
order by n;
proc sql noprint;
select tpos into: fake_refline_values_neg separated by " "
from &dsdin._neg_fk
where tag=1
order by n;
*All max_neg_fale_axis_var will be 0;
*Need to remove the 1st num in fake_refline_values;
%let fake_refline_values_neg=%sysfunc(prxchange(s/^[\-\d\.]+\s*//,-1,&fake_refline_values_neg));

*focus on positive axis values now;
data &dsdin._pos_fk;
set &dsdin._pos_fk;
min_pos=0;
run;
proc sql noprint;
select ceil(&axis_var),tpos,min_pos
into: max_pos_y4grps separated by " ",
    : fake_refline_values_pos separated by " ",
    : min_pos_y4grps separated by " "
from &dsdin._pos_fk
where tag=1
order by n;
*All min_pos_false_axis_var will be 0;
*Need to remove the last num in fake_refline_values;
%let fake_refline_values_pos=%sysfunc(prxchange(s/ [\d\.]+$//,-1,&fake_refline_values_pos));

%let fake_refline_values=&fake_refline_values_neg &fake_refline_values_pos;
%let max_y4grps=&max_neg_y4grps &max_pos_y4grps;
%let min_y4grps=&min_neg_y4grps &min_pos_y4grps;

%put max_y4grps: &max_y4grps;
%put min_y4grps: &min_y4grps;

*Also get the min_val when ll=1;
*Get the macro var fake_max_y value;
data _null_;
set &dsdout end=eof;
if eof then call symputx('fake_max_y',ceil(&new_fake_axis_var));
run;

%let fake_min_y=%scan(&min_y4grps,1,%str( ));
%let fake_min_y=%sysfunc(floor(&fake_min_y));

%let nums=;
*The macro &axis_step will affect the following codes;
*The default step is equal to 1, so there is no adjustment;
*If the step=2, then all _min_y and _end_ need to be minused by 1;

%do xi=1 %to %sysfunc(countw(&max_y4grps));
  *use %str( ) to prevent from lossing of negative nums;
                
	  	%let _min_y=%scan(&min_y4grps,&xi,%str( ));
                %if %sysevalf(&_min_y < 0) %then %do;
                  %let _end_=0;     
                %end;
                %else %do;
                  %let _min_y=%sysevalf(&_min_y+&axis_step,floor);
                  %let _end_=%sysevalf(%scan(&max_y4grps,&xi,%str( ))+&axis_step,ceil);
                %end;
                
                
               /* 
		%if %eval(&_min_y > -1) and %eval(&_min_y < 0)  %then %do;
                  *for negative axis, there is no offset of 1;
                  %let _min_y=%eval(&_min_y-1);
                  %let _end_=%eval(&_end_-1);
		%end;
	      */
		
		%put _min_y is &_min_y;
			
		%if %eval(&xi=1) %then %do;
                  %nums_in_range_adj_scale(st=&_min_y,end=&_end_,by=1,outmacrovar=nums&xi,
                   filter4scaledvals=%str(>0),scale=&fc2scale_pos_vals,quote=1);
		 %let nums=&&nums&xi;
		 *Need to replace the last value as empty;
                 %let nums=%sysfunc(prxchange(s/\S+$/" "/,-1,&nums));
		%end;
		
                %else %do;
		 %nums_in_range_adj_scale(st=&_min_y,end=&_end_,by=1,outmacrovar=nums&xi,
                   filter4scaledvals=%str(>0),scale=&fc2scale_pos_vals,quote=1);
		 *Need to replace the last value as empty;
		 %let new_nums=%sysfunc(prxchange(s/\S+$/" "/,-1,&&nums&xi));
		 %put modified new_nums are: &new_nums;
		 %let nums=&nums &new_nums;
		%end;
		
        %end;
	%let &yaxis_macro_labels=&nums;
	%put generated the global macro var &&yaxis_macro_labels for labeling y axis, which are: &&&yaxis_macro_labels;
		%put generated the global macro var fake_min_y, the value of which are all 0s;
	 %put generated the global macro var fake_max_y, the value of which is &fake_max_y;
		%put generated the global macro var fake_refline_values, the value of which can be used to make reflines to separate grps:;
		%put &fake_refline_values;
%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*******Test 1;
data a;
*blank space is represented by '20'x;
*infile cards dlm='20'x dsd truncover;
infile cards dlm='09'x dsd truncover;
input x1 x2 grp $;
cards;
-3	3	x
-2	3	x
-1	3	x
2	4.5	y
5	7	w
11	4	w
3	4	y
10	7	w
;
run;

options mprint mlogic symbolgen;
%make_fake_axis4NegPosVal_by_grps(
dsdin=a,
axis_var=x1,
axis_grp=grp,
new_fake_axis_var=new_x1,
dsdout=b,
yaxis_macro_labels=ylabelsmacro_var,
fc2scale_pos_vals=1
);
proc print data=b;run;

proc sgplot data=b;
scatter x=new_x1 y=x2/group=grpnum 
                      markerattrs=(symbol=circlefilled size=10);

*Adding type=discrete will make all axis values shown;
*otherwise,the axis may have different step from that of values;
xaxis display=(noticks) values=(&fake_min_y to &fake_max_y by 1) type=discrete valuesdisplay=(&ylabelsmacro_var) grid;

yaxis grid;
*Use the fake axis values corresponding to the var grp_end_tag=1 of each grpnum to create refline;

*The reflines would be the values;
refline 0/axis=x lineattrs=(thickness=5 color=darkgrey);
%let ref=%scan(&fake_refline_values,1,%str( ));
refline &ref/axis=x lineattrs=(thickness=5 color=darkgrey);
run;

*******Test 2;
data x0;
*gscatter_grp can be either numeric numbers or charaters;
*the var cnv should be negative for gene grp;
input chr st end cnv grp $ gscatter_grp;
*if cnv<0 then cnv=cnv*0.2;
cards;
1 400 500 -0.5 X1 0
1 700 900 -0.5 X1 0
1 100 101 1 a 1
1 200 201 3 b 1
1 400 401 0 b 2
1 600 601 2.2 a 2
1 700 701 2 c 3
1 800 801 3 c 3
1 900 901 8.9 c 3
1 1000 1001 4.3 d 4
1 900 3000 -1 X1 0
;
run;

options mprint mlogic symbolgen;
%make_fake_axis4NegPosVal_by_grps(
dsdin=x0,
axis_var=cnv,
axis_grp=grp,
new_fake_axis_var=new_cnv,
dsdout=b,
yaxis_macro_labels=ylabelsmacro_var,
fc2scale_pos_vals=1
);
proc print data=b;run;

ods graphics /reset=all height=800;
*Need to allocate enough height to use linear numbers by step for the yaxis;
proc sgplot data=b;
scatter x=st y=new_cnv/group=grp 
                      markerattrs=(symbol=circlefilled size=10);

*Adding type=discrete will make all axis values shown;
*otherwise,the axis may have different step from that of values;
*If using  type=discrete, sometime there would be missing values when the y values are not integer;
*type=discrete only shows inter values;
yaxis values=(&fake_min_y to &fake_max_y by 1) TYPE= linear display=(noticks) valuesdisplay=(&ylabelsmacro_var) grid;

xaxis grid;
*Use the fake axis values corresponding to the var grp_end_tag=1 of each grpnum to create refline;
refline 0/axis=y;
*The reflines would be the values of max_y2-1 and max_y3-1;
%let ref1=%scan(&fake_refline_values,1);
refline &ref1/axis=y lineattrs=(thickness=5 color=darkgrey);
%let ref2=%scan(&fake_refline_values,2);
refline &ref2/axis=y lineattrs=(thickness=5 color=darkgrey);
%let ref3=%scan(&fake_refline_values,3);
refline &ref3/axis=y lineattrs=(thickness=5 color=darkgrey);
%let ref4=%scan(&fake_refline_values,4);
refline &ref4/axis=y lineattrs=(thickness=5 color=darkgrey);
run;

*/

