%macro add_fake_pos_by_grp4nonnegvars(
dsdin,
axis_var,/*No negative values are allowed for the target axis var*/
axis_grp,
new_fake_axis_var,
dsdout, /*Two new variables, tag var and tpos, can be used to draw a ref line to separe each group*/
axis_step=1 /*Add extra step to separate each group for the end value of axis_var*/
);

/*
%let dsdin=a;
%let axis_grp=g;
%let axis_var=y;
%let dsdout=b;
%let axis_step=1;
%let new_fake_axis_var=fy;
*/

*Test whether there are negative values in the &dsdin;
*the macro only works for values >= 0;
proc sql noprint;
select count(&axis_var) into: neg_var_tot
from &dsdin
where &axis_var<0;


%if &neg_var_tot>0 %then %do;
 %put the macro only works for positve values, and you dsd &dsdin contains &neg_var_tot number of negative values;
 %abort 255;
%end;


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

proc sort data=&dsdin;
by &axis_grp &axis_var;
run;

data &dsdin;
set &dsdin;
*Scale position value and make it larger by fold change;
*if &axis_var>0 then &axis_var=&fc2scale_pos_vals*&axis_var;
run;


data &dsdout;
retain tpos 0 step &axis_step grp_n 0 grpnum 0;
set &dsdin;

n=_n_;
*add the var grp_n for sorting the values inside each group;
*which would be handy to handle all negative values by using the macro;
*the method is simply to change all negative values into positve, ane then;
*use this macro. Finally, flip the order of fake axis values by this var grp_n later;
*grp_n need to be put in the retain command;

if first.&axis_grp then do;
 fst_tag=1;
 grpnum=grpnum+1;
 grp_n=1;
 if n=1 then do;
   *important to make tpos as 0 when n=1;
   tpos=tpos;
   &new_fake_axis_var=&axis_var;
 end;
 else do;
   &new_fake_axis_var=&axis_var + tpos;
 end;
end;

if last.&axis_grp then do;
   grp_n=grp_n+1;
   tag=1;
   &new_fake_axis_var=tpos + &axis_var;
   if not first.&axis_grp then do;
      *only floor but not ceil can be used here;
      tpos=ceil(&axis_var) + tpos + step;
   end;
end;

if (not first.&axis_grp) and (not last.&axis_grp) then do;
 grp_n=grp_n+1;
 &new_fake_axis_var=&axis_var + tpos;
end;

by &axis_grp;

run;

*Also add a new var to indicate the middle axis value for each group;
data &dsdout;
retain mid_val 0;
set &dsdout;
if tag=1 then mid_val=tpos-0.5*(tpos-mid_val);
run;

data &dsdout;
set &dsdout;
*reassign missing value for mid_val whoes tag is not 1;
if tag=. then mid_val=.;
run;

*Make the last maximum value minus the step;
data &dsdout;
set &dsdout end=eoff;
if eoff then tpos=tpos-step;
run;


%mend;


/*Demo


data a;
input x y g $;
cards;
1 2 a
3 4 a1
5 6 a1
0 1 b
1 3 b
2 5 b
3 1 c
4 2 c
5 3 c
;
proc print;run;

*Demo1: for a dataset with all positive axis values;
%add_fake_pos_by_grp4nonnegvars(
dsdin=a,
axis_var=y,
axis_grp=g,
new_fake_axis_var=fy,
dsdout=b,
axis_step=1
);

*Demo2: for a dataset with all negative axis values;
*First change the dataset by making all negative values into positve ones;
data t;
input x y g $;
y=-1*y;
cards;
1 2 a
3 4 a1
5 6 a1
0 1 b
1 3 b
2 5 b
3 1 c
4 2 c
5 3 c
;
proc print;run;
*for evaluation only;
data t;set t;y=-1*y;run;

%add_fake_pos_by_grp4nonnegvars(
dsdin=t,
axis_var=y,
axis_grp=g,
new_fake_axis_var=fy,
dsdout=w,
axis_step=1
);
*flip the postive vars, including mid_val, tpos, y, fy, and grp_n, as negative;
data w;set w;
mid_val=mid_val*-1;grp_n=-1*grp_n;
tpos=tpos*-1;y=y*-1;fy=fy*-1;
proc print;run;



*/


