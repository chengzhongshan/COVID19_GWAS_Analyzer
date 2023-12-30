%macro bed_region_plot_by_grp(
bed_dsd,
chr_var,
st_var,
end_var,
grp_var,
yval_var,
linethickness=20,
track_width=800,
track_height=400,
dist2st_and_end=0
);
%number_rows_by_grp(dsdin=&bed_dsd,grp_var=&grp_var,num_var4sort=&st_var,descending_or_not=0,dsdout=x1);
data x1(keep=&chr_var pos &yval_var &grp_var ord st end);
set x1;
array X{2} &st_var &end_var;
do i=1 to 2;
 pos=X{i};
 output;
end;
run;
/*Get max grp number for split data into different dsd*/;
proc sql noprint;
select max(ord),floor(min(&yval_var)),ceil(max(&yval_var)),min(&st_var)-&dist2st_and_end,max(&end_var)+&dist2st_and_end 
       into: max_ord,: min_y,: max_y,: min_x,: max_x
from x1;
%if %eval(&min_x<0) %then %do;
    %let min_x=0;
%end;
/*
data tmp;
set x1(keep=&grp_var &yval_var);
proc sort data=tmp nodupkeys;by &yval_var &grp_var;
run;
proc sql noprint;
select quote(&grp_var) into: y_grp_values separated by " "
from tmp
order by &yval_var;
drop table tmp;
*/

data tmp;
do i=&min_y to &max_y;
output;
end;
run;
proc sql noprint;
select i into: y_axis_values separated by " "
from tmp;
drop table tmp;

/***********************No need this, as it generates missing group that will be put into the legend
in in the final figure*/
/*data x1;*/
/*set x1;*/
/*%do i=1 %to &max_ord;*/
/*if ord=&i then do;*/
/*  &grp_var.&i=&grp_var;*/
/*  pos&i=pos;*/
/*  &yval_var.&i=&yval_var;*/
/*  output;*/
/*end;*/
/*%end;*/
/*run;*/
/************************************************************************************************/


/*Need to fill these missing values with pair of non-missing values,
otherwise, the missing values will be a group that will be included 
in the legend in the final figure*/
%do gi=1 %to &max_ord;
data y&gi(keep=ord &grp_var&gi pos&gi &yval_var&gi);
set x1;
if ord=&gi then do;
  &grp_var&gi=&grp_var;
  pos&gi=pos;
  &yval_var&gi=&yval_var;
  output;
end;
else do;
  /*grp_var may be numeric or char, 
   just use its original value here,
   will remove it later*/
  &grp_var&gi=&grp_var;
  pos&gi=.;
		label pos&gi="Relative position (bp)";
  &yval_var&gi=.;
		label &yval_var&gi="Group";
  output;
end;
run;

/*proc sort data=y&gi;by &grp_var&gi ord pos&gi;*/
/*run;*/

/*get the 1st two records without missing values,
which will be used for fill these missing values later*/
data y&gi._ y&gi._missing;
set y&gi;
if pos&gi^=. then output y&gi._;
else output y&gi._missing;
/*create the common var n with values of 1 or 2
for matching with non-missing values from y1_*/
data y&gi._missing;
set y&gi._missing;
if mod(_n_,2)=0 then n=2;
else n=1;
/*Also get the 1st two non-missing values and 
label them with 1 and 2 for matching*/
data y&gi._1;
set y&gi._;
n=_n_;
if _n_<=2;
run;
proc sql;
create table y&gi._filled as
select a.n as n&gi, b.*
from y&gi._missing as a,
     y&gi._1 as b
where a.n=b.n;
/*merge y1_filled with y1_*/
data y&gi._final(drop=ord n);
set y&gi._filled(drop=n&gi) y&gi._;
run;
%end;

data final;
%do i=1 %to &max_ord;
set y&i._final;
%end;
run;
*documentation for adjusting axis for layout overlay;
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatug/p1pqfzgbuzbpkzn1mrbzhgggvhkz.htm;
proc template;
define statgraph Bedgraph;
dynamic _chr _pos _value _G;
begingraph / designwidth=&track_width designheight=&track_height;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
         layout overlay/yaxisopts=(
                        type=linear offsetmin=0.1 offsetmax=0.1
                        linearopts=(minorticks=false tickvaluelist=(&y_axis_values))
                        )
                        xaxisopts=(linearopts=(viewmin=&min_x viewmax=&max_x));
                        /* Need to add this into linearopts later: tickdisplaylist=(&y_grp_values)*/
		 %do i=1 %to &max_ord;
	       %if &i=1 %then %do;
		     referenceline y=0 /lineattrs=(color=black pattern=1 thickness=2);
						%if &min_y<0 %then %do;
						  %do _yi_=&min_y %to -1;
		       referenceline y=&_yi_ /lineattrs=(color=black pattern=2 thickness=0.5);
								%end;
						%end;
						%else %do;
						  %do yi=1 %to &max_y;
		        referenceline y=&yi /lineattrs=(color=black pattern=2 thickness=0.5);
								%end;
						%end;
		   %end;

               seriesplot x=pos&i y=&yval_var.&i / group=&grp_var.&i name='series' connectorder=xaxis 
                                      lineattrs=(pattern=SOLID thickness=&linethickness)
                                      name="series&i"
                                      ;
         %end;	
      endlayout; 
	  sidebar /align=bottom;
	  discretelegend "series1"; 
	  endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=WORK.final template=BedGraph;
dynamic _chr="&chr_var";
run;

%mend;

/*Demo:

data x0;
input chr st end cnv grp $;
cards;
1 100 300 1 a
1 200 400 3 a
1 400 500 0 b
1 600 800 3 b
1 700 1800 2 c
;
run;

options mprint mlogic symbolgen;

%bed_region_plot_by_grp(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
yval_var=cnv,
linethickness=30
);

*make the same grp have the same cnv value to draw regions of the same grp together;
*Note: changing ngrp value leads to the separation or combination of different regions to be draw in a same line;
%char_grp_to_num_grp(dsdin=x0,grp_vars4sort=grp,descending_or_not=0,dsdout=x1,num_grp_output_name=ngrp);
%bed_region_plot_by_grp(
bed_dsd=x1,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
yval_var=ngrp,
linethickness=20,
track_width=1000,
track_height=200,
dist2st_and_end=50000
);

*/
