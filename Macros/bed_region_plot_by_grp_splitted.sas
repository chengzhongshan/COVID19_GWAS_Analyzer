%macro bed_region_plot_by_grp_splitted(
bed_dsd,
chr_var,
st_var,
end_var,
grp_var,/*bed regions will be colored according to the group membership*/
val_var4bed_reg,
indv_var,/*If empty, the macro will draw bed regions without considering individual information*/
inethickness=20
);
*Note: this macro will make bed plot for each individual and color each bed region by group!;

/*Get the unique individual elements*/
%if &indv_var ne %then %do;
proc sql noprint;
select unique(&indv_var) into: indvs separated by " "
from &bed_dsd;
select count(unique(&indv_var)) into: num_indvs
from &bed_dsd;
%end;
%else %do;
%let indvs=ALL;
%let num_indvs=1;
%end;

*Get the max abs value of val_var4bed_reg;
proc sql noprint;
select ceil(max(abs(&val_var4bed_reg)))	into: max_y
from &bed_dsd;

/*Generate bed plot for each individual and color each bed region by group;*/
%do indi=1 %to &num_indvs;

/*Create subset dataset for each individual*/
 %let indv=%scan(&indvs,&indi,%str( ));
 %put working on the individual &indv;
 data &bed_dsd.&indi;
 set &bed_dsd;
 %if &indv^="ALL" %then %do;
 where &indv_var="&indv";
 %end;
 run;

%number_rows_by_grp(dsdin=&bed_dsd.&indi,
grp_var=&grp_var,num_var4sort=&st_var,
descending_or_not=0,dsdout=x1);

data x1(keep=&chr_var pos &val_var4bed_reg &grp_var ord);
set x1;
array X{2} &st_var &end_var;
do i=1 to 2;
 pos=X{i};
 output;
end;
run;
/*Get max grp number for split data into different dsd*/;
proc sql noprint;
select max(ord) into: max_ord
from x1;

/***********************No need this, as it generate missing group that will be put into the legend
in in the final figure*/
/*data x1;*/
/*set x1;*/
/*%do i=1 %to &max_ord;*/
/*if ord=&i then do;*/
/*  &grp_var.&i=&grp_var;*/
/*  pos&i=pos;*/
/*  &val_var4bed_reg.&i=&val_var4bed_reg;*/
/*  output;*/
/*end;*/
/*%end;*/
/*run;*/
/************************************************************************************************/


/*Need to fill these missing values with pair of non-missing values,
otherwise, the missing values will be a group that will be included 
in the legend in the final figure*/
%do gi=1 %to &max_ord;
data y&gi(keep=ord &grp_var&gi pos&gi &val_var4bed_reg&gi);
set x1;
if ord=&gi then do;
  &grp_var&gi=&grp_var;
  pos&gi=pos;
  &val_var4bed_reg&gi=&val_var4bed_reg;
  output;
end;
else do;
  /*grp_var may be numeric or char, 
   just use its original value here,
   will remove it later*/
  &grp_var&gi=&grp_var;
  pos&gi=.;
  &val_var4bed_reg&gi=.;
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

/*Create a var to make the datalabel for the end position but not the start position*/
/*Note: only create the datalabel for the dataset y&gi._*/
data y&gi._;
set y&gi._;
endlabel&gi=&grp_var.&gi;
if mod(_n_,2)^=0 then endlabel&gi=""; 
run;

/*merge y1_filled with y1_*/
data y&gi._final(drop=ord n);
set y&gi._filled(drop=n&gi) y&gi._;
run;
%end;

data final&indi;
%do i=1 %to &max_ord;
set y&i._final;
%end;
run;


proc template;
define statgraph Bedgraph;
dynamic _chr _pos _value _G;
begingraph / designwidth=800 designheight=400;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
         layout overlay/yaxisopts=(type=linear offsetmin=0.1 offsetmax=0.1 label="&val_var4bed_reg.&i for sample &indv");
		 %do i=1 %to &max_ord;
	       %if &i=1 %then %do;
/*		     referenceline y=0 /lineattrs=(color=black pattern=1 thickness=2);*/
/*		     referenceline y=1 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=-1 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=-2 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=2 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=-3 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=3 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*           replace the above with a macro loop                                */
           %do ri=-&max_y %to &max_y;
		     %if &ri^=0 %then %do;
			 referenceline y=&ri /lineattrs=(color=black pattern=2 thickness=0.5);
			 %end;
			 %else %do;
			 referenceline y=0 /lineattrs=(color=black pattern=1 thickness=2);
			 %end;
           %end;
 
		   %end;

               seriesplot x=pos&i y=&val_var4bed_reg.&i / group=&grp_var.&i connectorder=xaxis 
                                      datalabel=endlabel&i datalabelattrs=(size=15)
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

ods listing sge=on;
*This will disable label collision;
ods graphics / reset labelmax=0 imagename="bed_plot4sample_&indv";
/*The title will not be included in the figure*/
title "Bed plot for individual &indv by the group &grp_var";
proc sgrender data=WORK.final&indi template=BedGraph
des="Bed plot for individual &indv by the group &grp_var";
/*Note: the description will be only appeared when 
hopping mouse over the figure that is included in the html output*/
dynamic _chr="&chr_var";
run;
ods listing close;
title;

%end;

%mend;

/*Demo:

data x0;
input chr st end cnv grp $ indv $;
cards;
1 100 300 1 a x
1 200 400 3 a x
1 400 500 0 b x
1 600 900 4 a y
1 1000 2000 2 b y
;
run;

options mprint mlogic symbolgen;
*Make bed plot by ALL individuals and group;
%bed_region_plot_by_grp_splitted(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
val_var4bed_reg=cnv,
indv_var=,
linethickness=30
);

*Make bed plot by individual and group;
%bed_region_plot_by_grp_splitted(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
val_var4bed_reg=cnv,
indv_var=indv,
linethickness=30
);

*/
