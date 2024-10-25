%macro make_fake_axis4NegPosVal_by_grps(/*The macro will scale up or down positive or negative values and generate 
yaxis macro labels with the original postive values; To keep using the original positive value but also to scale the ratio
between these positve and negative values, the macro variable NotChangePosVals is set to 1.
The other global macro variable called fake_refline_values, can be used by other procedures to
draw reference lines to separate each group into the final figure if required!
Note: if NotChangePosVals=1, the final negative tick values are scaled values and the macro is updated 
to adjust the axis labels for negative values; since the negative values
are used to draw gene track at the bottom, they will be replaced as " " in the final figure
Note: the output put dsdout contain modified values based on the input scale;
However, the macro variable yaxis_macro_labels is updated to use the original values 
to label axis, although the negative positive values may use different steps in the final axis labels!
*/
dsdin,
axis_var,/*Both negative and positive values of axis var are allowed to use this macro,
           but in each group, only positve (>0) or negative (<0) values are allowed,
           and all 0 axis var values will be excluded from the dsdin, 
           the above of which are the limitations of the macro!*/
axis_grp,
new_fake_axis_var,
dsdout,
yaxis_macro_labels=ylabelsmacro_var,
fc2scale_pos_vals=1, /*Use this fc to enlarge the proportion of positive values in the plots
               It seems that fc=2 is the best for the final ticks of different tracks;*/
NotChangePosVals=1, /*For making manhattan plot, it is better to fix the positive y values,
as scale down the positive values will lead to the y tick labels containing decimals, and
the SAS macro to making local Manhattan plot is set in default to only show integer ticks;
When fc2scale_pos_vals is < 1, the original positive values will be
scaled down to generate fake values; sometimes it is necessary to keep the original values 
but also achieve the goal of scale down these positve values. The workaround method is 
to scale up the negative value with the fold change 1/&fcscale_pos_vals;
Reason for keep the positive values but scale up the negative values:
The coveat for squeezing the positive values by amplifying the value for negative values is that;
the final figure ticks for the positive values will be with very few ticks in the y-axis; 
To rescue this, it is better to multiple both negative and positive values by the same scale value &yscale again;*/
mod_num2keep= /*For the final yaxis_macro_labels, default value for the current var  is empty for not filtering these elements by mod; when values, 
such as 2 or 3 are provided, only keep numbers that fulfil the mod(element,num)=0; 
Note that this will only be applied on numbers that are positve!*/
);

*This para is important for making correct fake axis;
%let axis_step=1;
************************************************************************;
*Get records with negative values in &dsdin;
data &dsdin._neg;
set &dsdin (where=(&axis_var<0));
*temporarily make all negative axis_var as positve ones;
&axis_var=&axis_var*-1;
%if &NotChangePosVals=1 %then %do;
&axis_var=&axis_var/&fc2scale_pos_vals;
%end;
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
/*
data &dsdin._neg_fk;
set &dsdin._neg_fk;
%if &NotChangePosVals=1 %then %do;
%end;
%else %do;
&new_fake_axis_var=&new_fake_axis_var*&fc2scale_pos_vals;
%end;
run;
*/

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
%if &NotChangePosVals=0 %then %do;
&axis_var=&axis_var*&fc2scale_pos_vals;
%end;
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
       %if &NotChangePosVals=0 %then %do;
                  %nums_in_range_adj_scale(st=&_min_y,end=&_end_,by=1,outmacrovar=nums&xi,
                   filter4scaledvals=%str(>0),scale=&fc2scale_pos_vals,quote=1,mod_num2keep=&mod_num2keep);
        %end;
       %else  %do;/*Scale back the nums when NotChangePosVals is true;*/
                  %nums_in_range_adj_scale(st=&_min_y,end=&_end_,by=1,outmacrovar=nums&xi,
                   filter4scaledvals=%str(>0),scale=1,quote=1,mod_num2keep=&mod_num2keep);
                  *Need to scale the negative values back to its original values for the axis ticks;
                  %if %sysfunc(prxmatch(/\-/,&&nums&xi)) %then %let nums&xi=%scale_nums_in_list(list=&&nums&xi,factor=%sysevalf(&fc2scale_pos_vals),contain_double_quote=1);
                  *Note: use . to represent single double quote, as SAS will crash if using single quote in prxchange;
                  %let nums&xi=%sysfunc(prxchange(s/[^\-][\-\d]+\.\d+./" "/,-1,&&nums&xi));
                  %put nums&xi are: &&nums&xi;

       %end;        
		 %let nums=&&nums&xi;
     %put &nums;
     %let nums=%sysfunc(prxchange(s/\.\d+//,-1,&nums));
     %put &nums;
		 *Need to replace the last value as empty;
     *Note: the rgx will remove the last tick label that is overlapped with reference line;
     *Let the rgx not match -\d+, such as -1, -2, ..., and other negative numbers;
     *Otherwise, this bug would lead to unmatched quotes in the macro;
      %let nums=%sysfunc(prxchange(s/[^\-](\d+).$/" "/,-1,&nums));
/*      %let nums=%trim(%left(&nums));*/
		%end;
		
    %else %do;
       %if &NotChangePosVals=0 %then %do;
		              %nums_in_range_adj_scale(st=&_min_y,end=&_end_,by=1,outmacrovar=nums&xi,
                   filter4scaledvals=%str(>0),scale=&fc2scale_pos_vals,quote=1,mod_num2keep=&mod_num2keep);
       %end;
       %else %do;/*Scale back the negative nums when NotChangePosVals is true;*/
		              %nums_in_range_adj_scale(st=&_min_y,end=&_end_,by=1,outmacrovar=nums&xi,
                   filter4scaledvals=%str(>0),scale=1,quote=1,mod_num2keep=&mod_num2keep);
       %end;

		 *Need to replace the last value as empty;

     %let nums&xi=%sysfunc(prxchange(s/\.0//,-1,&&nums&xi));
     %put Unmodified num&xi are:;
     %put &&nums&xi;
     *Note: the rgx will remove the last element as empty;
     *Note: the rgx will remove the last tick label that is overlapped with reference line;
		 %let new_nums=%qsysfunc(prxchange(s/[^\-](\d+).$/" "/,-1,&&nums&xi));
		 %put modified new_nums are:; 
     %put &new_nums;
		 %let nums=&nums &new_nums;
     *If the value of &nums is too long to be truncated to contain an unmatched quote;

		%end;
		
   %end;

   *Need to remove fake_refline_values in the list of yaxis_macro_labels;
   %do ni=1 %to %ntokens(&fake_refline_values);
           %if &ni=1 %then %do;
               %let _refnum_=%scan(&fake_refline_values,1,%str( ));
           %end;
           %else %do;
               *Note: the fake refline values need to be substracted with the fake refline value before it;
						   %let _refnum_=%sysevalf(%scan(&fake_refline_values,&ni,%str( )) - %scan(&fake_refline_values,&ni-1,%str( )));
            %end;
            %let nums=%sysfunc(prxchange(s/[^\-]&_refnum_\D/" "/,1,&nums));
    %end;
     *Also need to remove the last fake refline value as the top value;
     *Note: the rgx will remove the last tick label that is overlapped with reference line;
     %let nums=%sysfunc(prxchange(s/[^\-](\d+).$/" "/,1,&nums));

	%let &yaxis_macro_labels=&nums;
	%put generated the global macro var &&yaxis_macro_labels for labeling y axis, which are: &&&yaxis_macro_labels;
		%put generated the global macro var fake_min_y, the value of which are all 0s;
	 %put generated the global macro var fake_max_y, the value of which is &fake_max_y;
		%put generated the global macro var fake_refline_values, the value of which can be used to make reflines to separate grps:;
		%put &fake_refline_values;
/*    %abort 255;*/

%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*******Test 1;
data a;
*blank space is represented by '20'x;
infile cards dlm='20'x dsd truncover;
*infile cards dlm='09'x dsd truncover;
input x1 x2 grp $;
cards;
-4 3 x
-2 3 x
-6 3 x
2 4.5 y
5 7 w
11 4 w
3 4 y
10 7 w
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
fc2scale_pos_vals=2,
NotChangePosVals=1,
mod_num2keep=3
);

*Note that when NotChangePosVals=1, these negative values will be squeezed by the fc change;
*The above macro is updated to adjust the axis labels for negative values;
*Due to the use of discrete x-axis, any noninteger will be rounded into close integer!;
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
%put &ylabelsmacro_var;
%put &fake_refline_values;

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
run;

*/

