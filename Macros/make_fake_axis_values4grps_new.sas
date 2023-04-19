%macro make_fake_axis_values4grps_new(
dsdin,
axis_var,
axis_grp,
new_fake_axis_var,
dsdout,
yaxis_macro_labels=ylabelsmacro_var
);

*Fix a bug when only one record in a group;
*make an extra copy for the records to make it has >1 records;
*This is because the script will not be able to update corrected;
*y axis labels if there is only one record for a group;
proc sql;
create table _single_ as 
select *
from &dsdin
group by &axis_grp
having count(&axis_grp)=1;
data &dsdin;
set &dsdin _single_;
run;

*add 2 to the max value to make grps separated better;
proc sql;
create table &dsdout as
select a.*,&axis_var as &new_fake_axis_var,
/*        floor(min(&axis_var)) as min_val, */
       0 as min_val,
       ceil(max(&axis_var))+2 as max_val
from &dsdin as a
group by &axis_grp
order by &axis_grp,&axis_var;

data &dsdout;
retain max grpnum mtag new_min_y 0;
set &dsdout;
grp_end_tag=0;

*For every first elelemt in a group;
if first.&axis_grp then do;
  if &axis_var<min_val then do;
     min_val=floor(&axis_var);
  end;
 new_min_y=min_val;
*important to set max^=0;
*No other value can be used, as 0 is very special;
 if max^=0 then do;
/*	 if min_val<0 then do;*/
/*		 *The 1st one of each grp would be the min_val;*/
/*   &new_fake_axis_var=max-min_val;*/
/*		end;*/
/*		else do;*/
/*   &new_fake_axis_var=&axis_var+max;*/
/*		end;*/
  &new_fake_axis_var=(&axis_var-min_val)+max;
  grpnum=grpnum+1;
 end;
 else do;
  &new_fake_axis_var=&axis_var;
  mtag=1;
  grpnum=1;
 end;
end;

*For every last element in a group;
else if last.&axis_grp then do;
   min_val=new_min_y;
   &new_fake_axis_var=(&axis_var-min_val)+max;
   max=ceil(&new_fake_axis_var)+2;
   grp_end_tag=1;
end;

*For elements that are not the 1st or the last elements in a group;
else do;
  min_val=new_min_y;
  &new_fake_axis_var=&axis_var-min_val+max;  
end;
output;
*drop min max min_val max_val;
*Make sure to sort by two vars;
by &axis_grp &axis_var;
run;

*Generate real y axis labels;
%global &yaxis_macro_labels fake_max_y fake_min_y fake_refline_values;
proc sql noprint;
select max_val,min_val,max-1 
into: max_y4grps separated by " ",
    : min_y4grps separated by " ",
				: fake_refline_values separated by " "
from &dsdout
where grp_end_tag=1
order by grpnum,&axis_var;

%put max_y4grps: &max_y4grps;
%put min_y4grps: &min_y4grps;

*Also get the min_val when grp_end_tag=1;
*Get the macro var fake_max_y value;
data _null_;
set &dsdout end=eof;
if eof then call symputx('fake_max_y',&new_fake_axis_var);
run;

%let fake_min_y=%scan(&min_y4grps,1,%str( ));

%let nums=;
%do xi=1 %to %sysfunc(countw(&max_y4grps));
  *use %str( ) to prevent from lossing of negative nums;
		%let _min_y=%scan(&min_y4grps,&xi,%str( ));
		%put _min_y is &_min_y;
		%if %eval(&xi=1) %then %do;
    %nums_in_range(st=&_min_y,end=%eval(%scan(&max_y4grps,&xi,%str( ))-1),by=1,outmacrovar=nums&xi,quote=1);
				%let nums=&&nums&xi;
				*Need to replace the last value as empty;
    %let nums=%sysfunc(prxchange(s/\S+$/" "/,-1,&nums));*/
		%end;
		%else %do;
		  %nums_in_range(st=&_min_y,end=%eval(%scan(&max_y4grps,&xi,%str( ))-1),by=1,outmacrovar=nums&xi,quote=1);
				*Need to replace the last value as empty;
				%let new_nums=%sysfunc(prxchange(s/\S+$/" "/,-1,&&nums&xi));
				%put modified new_nums are: &new_nums;
				%let nums=&nums &new_nums;
		%end;
	%end;
	%let &yaxis_macro_labels=&nums;
	%put generated the global macro var &&yaxis_macro_labels for labeling y axis, which are: &&&yaxis_macro_labels;
		%put generated the global macro var fake_min_y, the value of which is &fake_min_y;
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
infile cards dlm='20'x dsd truncover;
*infile cards dlm='09'x dsd truncover;
input x1 x2 grp $;
cards;
-3	3	x
-2	3	x
1	3	x
2	4	y
5	7	w
11	4	w
7	4	x
3	4	y
10	7	w
;
run;

options mprint mlogic symbolgen;
%make_fake_axis_values4grps_new(
dsdin=a,
axis_var=x1,
axis_grp=grp,
new_fake_axis_var=new_x1,
dsdout=b,
yaxis_macro_labels=ylabelsmacro_var
);
proc print data=b;run;

proc sgplot data=b;
scatter x=new_x1 y=x2/group=grpnum 
                      markerattrs=(symbol=circlefilled size=10);

*Adding type=discrete will make all axis values shown;
*otherwise,the axis may have different step from that of values;
xaxis values=(&fake_min_y to &fake_max_y by 1) type=discrete valuesdisplay=(&ylabelsmacro_var) grid;

yaxis grid;
*Use the fake axis values corresponding to the var grp_end_tag=1 of each grpnum to create refline;

*The reflines would be the values of max_y2-1 and max_y3-1;
refline 12/axis=x lineattrs=(thickness=5 color=darkgrey);
refline 24/axis=x lineattrs=(thickness=5 color=darkgrey);
run;

*******Test 2;
*Problem here with non integers!;
data x0;
*gscatter_grp can be either numeric numbers or charaters;
*the var cnv should be negative for gene grp;
input chr st end cnv grp $ gscatter_grp;
cards;
1 400 500 -2 X1 0
1 700 900 -2 X1 0
1 100 101 1 a 1
1 200 201 3.8 b 1
1 400 401 0 b 2
1 600 601 2 a 2
1 700 701 2 c 3
1 800 801 3 c 3
1 900 901 8.9 c 3
1 1000 1001 4 d 4
1 900 3000 -1 agene 0
;
run;

options mprint mlogic symbolgen;
%make_fake_axis_values4grps_new(
dsdin=x0,
axis_var=cnv,
axis_grp=gscatter_grp,
new_fake_axis_var=new_cnv,
dsdout=b,
yaxis_macro_labels=ylabelsmacro_var
);
proc print data=b;run;

proc sgplot data=b;
scatter x=st y=new_cnv/group=gscatter_grp 
                      markerattrs=(symbol=circlefilled size=10);

*Adding type=discrete will make all axis values shown;
*otherwise,the axis may have different step from that of values;
yaxis values=(&fake_min_y to &fake_max_y by 1) valuesdisplay=(&ylabelsmacro_var) grid;
*However, when values and valuesdisplay are not matched, some data points may lost!;
*type=discrete valuesdisplay=(&ylabelsmacro_var) grid;

xaxis grid;
*Use the fake axis values corresponding to the var grp_end_tag=1 of each grpnum to create refline;

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

