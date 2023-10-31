%macro Lattice_gscatter_over_bed_track_(/*Old macro without adding the textplot section for labeling selected dots in scatterplots*/
bed_dsd,
/*Too many bed regions (>1000) for the gene track will 
slow down the macro dramatically;
Note: the macro will change the input bed_dsd 
when supplying xaxis_viewmin and xaxis_viewmax;
*/
chr_var,
st_var,
end_var,
grp_var,
scatter_grp_var,
lattice_subgrp_var,
yval_var,
yaxis_label=Group,
linethickness=20,
track_width=800,
track_height=400,
dist2st_and_end=0,
dotsize=10,
debug=0,
add_grp_anno=1, /*This will add group names, such as gene labels, to each member of grp_var*/
grp_font_size=8,
grp_anno_font_type=italic, /*other type: normal*/
shift_text_yval=0.1, /*add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis;
                      Change it with the macro var pct4neg_y!*/
yaxis_offset4min=0.05, /*provide 0-1 value or auto to offset the min of the yaxis*/
yaxis_offset4max=0.05, /*provide 0-1 value or auto or to offset the max of the yaxis*/
xaxis_offset4min=0.02, /*provide 0-1 value or auto  to offset the min of the xaxis*/
xaxis_offset4max=0.02, /*provide 0-1 value or auto to offset the max of the xaxis*/
fig_fmt=svg, /*output figure formats: svg, png, jpg, and others*/
refline_thickness=5,/*Use thick refline to separate different tracks*/
refline_color=lightgray,/*Color for reflines*/
pct4neg_y=1.5, /*the most often used value is 1;
              compacting the bed track y values by increasing the scatterplot scale, 
              which can reduce the bed trace spaces; It seems that two-fold increasement
              leads to better ticks for different tracks!
              Use value >1 will increase the gene tract, while value < 1 will reduce it!
              Note: when there are only 1 or 2 scatterplots, it is better to provide value = 0.5;
              */
NotDrawScatterPlot=0,/*This filter will be useful when it is only wanted to draw the bottom bed track
without of the scatterplot; this is the idea solution to draw gene track only!*/ 

offsety=0.05,/*If NotDrowScatterPlot=1, this value will be subtracted from negative gene group value;
This enables the upper and lower part have enough blank space for gene track*/

makedotheatmap=1,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot*/

color_resp_var=,/*Use value of the var to draw colormap of dots in scatterplot
if empty, the default var would be the same as that of yval_var;*/

makeheatmapdotintooneline=0,/*This will make all dots have the same yaxis value but have different colors 
based on its real value in the heatmap plot; To keep the original dot y axis value, assign 0 to the macro var
This would be handy when there are multiple subgrps represented by different y-axis values! By modifying
the y-axis values for these subgrps, the macro can plot them separately in each subtrack!
*/
           
mk_fake_axis_with_updated_func=1, /*The new func make the xaxis more compacted 
                                   between gene tracks and scatter plots;*/
sameyaxis4scatter=1,/*Make the same y-axis for scatterplots*/ 
maxyvalue4truncat=30,/*Asign yaxis_value >maxyvalue4trancat as the value of maxyvalue4trancat*/ 
adjval4header=0.5, /*Move down scatter group header by value*/
ordered_sc_grpnames= ,/*Labels for each scatter plot from down to up in order
                       Use _ to replace blank space within each name and all
                       _ will be changed into black space by the macro at the end*/
xaxis_label=%nrstr(Position (bp) on chromosome &chr_name), /*The macro var &chr_name will be unquoted after resolved*/        
xaxis_viewmin=,/*arbitrary xaxis min value to show the figure, and it requires to work with thresholdmin=0*/
xaxis_viewmax=,/*arbitrary xaxis max vale to show the figure, and it requires to go along with thresholdmax=0*/
scatterdotcols=green orange, /*set colors for the beta directions 
(negative and positve values) in scatterplots*/             
dataContrastCols=%str()
/*Note: these colors will be used for the gene track but not the scatterplot;
%str(lightblue lightgreen
CXFFF000 CXFF7F00 CXFF00FF CXFF0000 CXEAADEA CXE6E8FA CXDB9370 CXDB70DB CXD9D919 CXD8D8BF 
CXCD7F32 CXC0C0C0 CXBC8F8F CXB87333 CXB5A642 CXADEAEA CXA67D3D CXA62A2A CX9F9F5F CX9F5F9F 
CX97694F CX8E236B CX8E2323 CX8C7853 CX8C1717 CX871F78 CX856363 CX855E42 CX70DB93 CX5F9F9F 
CX5C4033 CX545454 CX4F2F4F CX4E2F2F CX32CD32 CX2F4F2F CX238E23 CX236B8E CX23238E CX00FFFF 
CX00FF00 CX0000FF CX000000
)*/

/*Note: default is to use %str(), which will apply system colors automatically;
add the following colors separated by blank space if desired,
CXADD8E6 CX98FB98 CXF08080 CX0000FF CXFFF00 CX9F5F9F CXA62A2A CX5F9F9F CX871F78
lightblue lightgreen lightcoral and others for the above!
https://support.sas.com/rnd/base/ods/templateFAQ/Template_colors.html
BLACK #FFFFFF
BLUE #0000FF
YELLOW #FFF000
BLUE VIOLET #9F5F9F
BROWN #A62A2A
CADET BLUE #5F9F9F
DARK BROWN #5C4033
DARK PURPLE #871F78
DUSTY ROSE #856363
GOLD #CD7F32
KHAKI #9F9F5F
NAVY BLUE #23238E
PINK #BC8F8F
SILVER #E6E8FA
TURQUOISE #ADEAEA
RED #FF0000
MAGENTA #FF00FF
BLACK #000000
BRASS #B5A642
BRONZE #8C7853
COPPER #B87333
DARK GREEN #2F4F2F
DARK TAN #97694F
FIREBRICK #8E2323
GREY #C0C0C0
LIME GREEN 32CD32
ORANGE #FF7F00
PLUM #EAADEA
STEEL BLUE #236B8E
VIOLET #4F2F4F
GREEN #00FF00
CYAN #00FFFF
AQUAMARINE #70DB93
BRIGHT GOLD #D9D919
BRONZE II #A67D3D
CORAL #FF7F00
DARK WOOD #855E42
DIM GREY #545454
FOREST GREEN #238E23
INDIAN RED #4E2F2F
MAROON #8E236B
ORCHARD #DB70DB
SCARLET #8C1717
TAN #DB9370
WHEAT #D8D8BF
*/
);
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/p0i3rles1y5mvsn1hrq3i2271rmi.htm;
*SAS marker symbols;


%Check_VarnamesInDsd(indsd=&bed_dsd,Rgx=&color_resp_var,exist_tag=HasVar);
%if %length(&HasVar)=0 %then %do;
 %put The color_resp_var: &color_resp_var does not exist in the sas dsd &bed_dsd;
 %abort 255;
%end;

*Restrict the min and max positions based on the customized viewmin and viewmax;
%put Going to reset the bed positions between xaxis_viewmin and xaxis_viewmax;
data &bed_dsd;
set &bed_dsd;
%if %length(&xaxis_viewmin)>0 %then %do;
if &st_var <= &xaxis_viewmin and &end_var >= &xaxis_viewmin and &yval_var<0 
then &st_var=&xaxis_viewmin;
if &end_var < &xaxis_viewmin 
then delete;
%end;
%if %length(&xaxis_viewmax)>0 %then %do;
if &end_var >= &xaxis_viewmax and &st_var <= &xaxis_viewmax and &yval_var<0 
then &end_var=&xaxis_viewmax;
if &end_var > &xaxis_viewmax 
then delete;
%end;
run;

%if %sysevalf(%length(&xaxis_viewmin)>0 or %length(&xaxis_viewmax)>0) %then %do;
  *Also need to adjust the negative y values;
  *for the genes after exclusion of bed regions by customized axis range;
  proc sql noprint;
  select max(&&yval_var) into: min_neg
  from &bed_dsd
  where &yval_var<0;
  data &bed_dsd;
  set &bed_dsd;
  if &yval_var<0 then &yval_var=&yval_var-&min_neg-1;
  run;
%end;

/* %abort 255; */


*Get the total number of distinct elements of scatter_grp_var;
*if n>5, the macro will not draw dashed reference lines for y-axis;
proc sql noprint;
select count(&scatter_grp_var) into: totsc
from (
select distinct &scatter_grp_var
    from &bed_dsd
);
%if &totsc>7 %then %let makeheatmapdotintooneline=1;

%if %eval(&NotDrawScatterPlot=1) %then %do;
   %put The macro will only draw the bottom bed track will will keep negative y values only;
   data &bed_dsd;
   set &bed_dsd;
   where &yval_var<0;
   run;
%end;

*Set default colors for negative and positive beta values in the scatterplot;
%if %length(&scatterdotcols)=0 %then %let scatterdotcols=green yellow;

%if &scatter_grp_var eq %then %do;
  %put Please provide the variable for scatter_grp_var, as it is empty!;
  %abort 255;
%end;
*A new numberic group, ord, is created in descending order;
*Note: it is important to sort the group by yval_var ascendingly;
*as the group order will be used to selected genes or non-gene groups for making scatter plot or gene track;

/* %number_rows_by_grp(dsdin=&bed_dsd,grp_var=&grp_var,num_var4sort=&yval_var,descending_or_not=0,dsdout=x1); */

*Use bed region distance to sort the dsd in descending order, and the bed region with the largest distance;
*would be the gene body, which will be subjected to draw with tranparent color;
data &bed_dsd;
set &bed_dsd;
dist=&end_var-&st_var+1;
*truncate large values with the threshold maxyvalue4truncat;
if &yval_var>=&maxyvalue4truncat then &yval_var=&maxyvalue4truncat;

%if &NotDrawScatterPlot=1 %then %do;
 *half the negative values to reduce spaces between different rows of genes in the final track;
 if &yval_var<0 then &yval_var=0.5*&yval_var-&offsety;
%end;

run;

*Also asign all heatmap grp with y-axis value as 0.75;
*keep the original y value as colorvalue;  
data &bed_dsd;
set &bed_dsd;

%if %length(&color_resp_var)=0 %then %do;
old_y=&yval_var;
%end;
%else %do;
old_y=&color_resp_var;
%end;

%if &makeheatmapdotintooneline=1 %then %do;
%*Change all postive y values into 0.75;
if &yval_var>=0 then &yval_var=0.75;
%end;

run;

%if &sameyaxis4scatter=1 %then %do;
*Add the maximum y values for each scatter group;
*This will enable the scatter plots have the same y axis;
*Enlarge the maxy4scatter by 1 will separate scatterplots better and have the right yaxis for these scatterplots;
   proc sql noprint;select ceil(max(&yval_var))+1 into: maxy4scatter from &bed_dsd;
   proc sort data=&bed_dsd;by &scatter_grp_var;
   data &bed_dsd;
   set &bed_dsd;
   if last.&scatter_grp_var and &yval_var>0 then do;
    output;
    &st_var=.;&end_var=.;&yval_var=&maxy4scatter;
    output;
   end;
   else do;
    output;
   end;
   by &scatter_grp_var;
%end;

%number_rows_by_grp(dsdin=&bed_dsd,grp_var=&grp_var,num_var4sort=dist,descending_or_not=1,dsdout=x1);

*The final x1 dataset is sorted by grp and yval_var, and a new var ord is created to label;
*each row with number in ascending order by grp;
*The x1 dataset will be splitted into subset dataset by ord;
*The 1st subset dsd will contain all grps with ord=1;
*However, other subset dsds may only contain one of these grps;
*It is important to rescue this by filling the missing grp with values from the 1st subset dsd;

proc sql noprint;
select unique(&chr_var) into: chr_name
from x1;
*remove leading spaces of &chr_name;
%let chr_name=%sysfunc(trim(&chr_name));

*Make fake y axis values by the scatter grp;
*Make sure the &scatter_grp_var have missing values for gene grps;
/*data x1;
set x1;
*Only integer negative values are allowed;
if &yval_var<0 then &yval_var=floor(&pct4neg_y*&yval_var);
run;
*/


*Determine whether there are both positive and negative grp values in the dsd x1;
*If there are no postive grp values, i.e., no grps for scatter plots;
*reasigne mk_fake_axis_with_updated_func=0;
proc sql noprint;
select count(*) into: tot_pos_grps
from x1
where &yval_var>0;

%if &tot_pos_grps=0 %then %do;
 %put There are no positive grp values for the scatter plots;
 %put We will not make fake axis using the updated function;
 %put Instead, default macro make_fake_axis_values4grps will be used to make fake axis values;
 %let mk_fake_axis_with_updated_func=0;
%end;


*Set scale based on the input value > 1 or < 1;
%if (&pct4neg_y<1) %then %do;
  %let yscale=%sysevalf(1/&pct4neg_y,ceil);
%end;
%else %do;
  %let yscale=%sysevalf(1/%sysevalf(&pct4neg_y,ceil));
%end;


%if %eval(&mk_fake_axis_with_updated_func=1 and &NotDrawScatterPlot=0) %then %do;

%make_fake_axis4NegPosVal_by_grps(
dsdin=x1,
axis_var=&yval_var, 
/*Both negative and positive values of axis var are allowed to use this macro,
but in each group, only positve (>0) or negative (<0) values are allowed,
and all 0 axis var values will be excluded from the dsdin, 
the above of which are the limitations of the macro!*/
axis_grp=&scatter_grp_var, /*although using the same input, this para is different from make_fake_axis_values4grps*/
new_fake_axis_var=&yval_var._new,
dsdout=x1,
yaxis_macro_labels=ylabelsmacro_var,
fc2scale_pos_vals=&yscale
/*Use this fc to enlarge the proportion of positive values in the plots
It seems that fc=2 is the best for the final ticks of different tracks;*/
);

%end;
%else %do;

%make_fake_axis_values4grps(
dsdin=x1,
axis_var=&yval_var,
axis_grp=&scatter_grp_var,
new_fake_axis_var=&yval_var._new,
dsdout=x1,
yaxis_macro_labels=ylabelsmacro_var,
fc2scale_pos_vals=&yscale
);

%end;

*The above will expand the y axis positive values by the fc=1/&pct4neg_y;

data x1;
set x1(drop=&yval_var);
rename &yval_var._new=&yval_var;
run;

/***HERE, it was wrong, need to figure out the reason!*/
/*data x1(rename=(&yval_var._new=&yval_var));*/
/*set x1;*/
/**Keep one copy of unchanged yval_var;*/
/*&yval_var._old=&yval_var;*/
/*run;*/
/*/*%abort 255;*/*/

*create macro vars for the fake y axis;
*This is just for evaluation, and the macro var fake_y_axis_vals is not used later;
proc sql noprint;
select &yval_var-1 into: fake_y_axis_vals separated by " "
from x1
where &yval_var>0 and grp_end_tag=1;
%put fake y axis values are &fake_y_axis_vals;


data x1(keep=old_y &chr_var pos &yval_var &grp_var ord st end &scatter_grp_var &lattice_subgrp_var);
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

*When the makeheatmapdotintooneline=1,the width of the top track would be shorter of 1 unit;
*To rescue this, add the value 1 to the max_y;
%if &makeheatmapdotintooneline=1 %then %let max_y=%sysevalf(&max_y+1); 

*Only keep records with yval_var <0 and the max y value;
*Exlude other data will prevent them from drawing in the bed track;
*These excluded data will be plotted with scatterplot;
data x2;
/* set x1(where=(&yval_var<0 or &yval_var=&max_y)); */
set x1(where=(&yval_var<0));
run;

*Get these unique negative values of y;
proc sql noprint;
select unique(abs(&yval_var)) into: yvals4reflines separated by ' '
from x2;

data tmp;
do i=&min_y to &max_y;
output;
end;
run;
proc sql noprint;
select i into: y_axis_values separated by " "
from tmp;
drop table tmp;

*Can not replace negative values with empty, as these axis values are for genes;
*The following codes should be deleted;
/*%let y_axis_values=%sysfunc(prxchange(s/-\d+/ /,-1,&y_axis_values));*/
*Also replace -1.0 and other similar negative values;
%let ylabelsmacro_var=%sysfunc(prxchange(s/-[\d\.]+/ /,-1,&ylabelsmacro_var));

/***********************No need this, as it generates missing group that will be put into the legend
in in the final figure*/
/*data x2;*/
/*set x2;*/
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

*Get the grp ord of gene grps;
proc sql noprint;
select unique(ord) into: genegrp_ords separated by " "
from X2;
select count(unique(&grp_var)) into:tot_genegrps
from X2;

/*
proc print data=x2;
run;
%abort 255;
*/

******************************************Prepare data for making series and scatter plots************************************************************;
/*Need to fill these missing values with pair of non-missing values,
otherwise, the missing values will be a group that will be included 
in the legend in the final figure*/
*Can not simplify the above process by using &tot_genegrps!;
*Do not use the following loop;
/* %do gi=1 %to &tot_genegrps; */
/* %do gi=1 %to &max_ord; */

%do gi=1 %to %ntokens(&genegrp_ords);
%let _gi_=%scan(&genegrp_ords,&gi,%str( ));
data _y&gi(keep=ord &grp_var&_gi_ pos&_gi_ &yval_var&_gi_);
*Only keep these y values <0 and the max y value for drawing bed track;
*Excluded data will be plotted via scatter plot;
set x2;
*Important to asign enough length for these grps, which are typical for gene names;
length  &grp_var&_gi_ $30.;
if ord=&_gi_ then do;
  &grp_var&_gi_=&grp_var;
  pos&_gi_=pos;
		label pos&_gi_="%unquote(&xaxis_label)";
  &yval_var&_gi_=&yval_var;
		label &yval_var&_gi_="&yaxis_label";
  output;
end;
*No need this, which only add missing values and makes the dataset too big;
/*else do;*/
   *Missing values will be generated for ord not equal to &_gi_;
  /*grp_var may be numeric or char, 
   just use its original value here,
   will remove it later*/
/*  &grp_var&_gi_=&grp_var;*/
/*  pos&_gi_=.;*/
/*		label pos&_gi_="Position (bp) on chromosome &chr_name";*/
/*  &yval_var&_gi_=.;*/
/*		label &yval_var&_gi_="&yaxis_label";*/
/*  output;*/
/*end;*/
run;


/*proc sort data=_y&_gi_;by &grp_var&_gi_ ord pos&_gi_;*/
/*run;*/

/*get the 1st two records without missing values,
which will be used for fill these missing values later*/
data _y&_gi_._ _y&_gi_._missing;
set _y&_gi_;
if pos&_gi_^=. then output _y&_gi_._;
else output _y&_gi_._missing;
/*create the common var n with values of 1 or 2
for matching with non-missing values from y1_*/
run;

*If the _y&_gi_ dsd is empty, delete it;
%delete_empty_dsd(dsd_in=work._y&_gi_._);
*Only if the dsd is not empty, run other command;
*Decide to skip the other processing if the _y&_gi_ dsd was deleted;
%iscolallmissing(dsd=_y&_gi_,colvar=pos&_gi_,outmacrovar=tot_missing);
%put &tot_missing;
/* %if %sysfunc(exist(work._y&_gi_._)) %then %do; */
%if "&tot_missing" eq "0" and %sysfunc(exist(work._y&_gi_._)) %then %do;
data _y&_gi_._missing;
set _y&_gi_._missing;
if mod(_n_,2)=0 then n=2;
else n=1;
/*Also get the 1st two non-missing values and 
label them with 1 and 2 for matching*/
data _y&_gi_._1;
set _y&_gi_._;
n=_n_;
if _n_<=2;
run;
proc sql;
create table _y&_gi_._filled as
select a.n as n&_gi_, b.*
from _y&_gi_._missing as a,
     _y&_gi_._1 as b
where a.n=b.n;
/*merge y1_filled with y1_*/
data _y&_gi_._final(drop=ord n);
set _y&_gi_._filled(drop=n&_gi_) _y&_gi_._;
run;

*better to add the &grp_var1 into other subset dsd, as these subset dsd may missing some genes;
%if 	%eval(&gi>1) %then %do;
proc sql;
create table y1fory&gi as
 select * from _y1_final
  where &grp_var.1 NOT in (select &grp_var.&gi from _y&gi._final);

*Manually make all pos1 as _n_ (out of the xaix range);
*leading to no drawing of the y1 region but inclusion of y1 legend in the final series plot;
data y1fory&gi;
set y1fory&gi;
pos1=_n_;
run;
  
proc sql;
create table _y&gi._final_ as 
select * from _y&gi._final 
union all
select * from y1fory&gi;

*Rename _y&gi._final_ back as _y&gi._final_;
*This is because the _y&gi._final is used by union and can not be replace within the same proc sql;
data _y&gi._final;
set _y&gi._final_;
*Make values < &min_x as .;
if pos&_gi_ < &min_x then pos&_gi_=.;
run;
%end;

/*The sorting of dataset by gene is important for the coloring in the seriesplot*/
proc sort data=_y&_gi_._final;
by grp&_gi_;
run;
%end;
%end;

data final;
set
%do ti=1 %to %sysfunc(countw(&genegrp_ords));
%let i=%scan(&genegrp_ords,&ti);
 %if %sysfunc(exist(work._y&i._final)) %then %do;
    _y&i._final
 %end;
%end;
;

/*
*change the Y6 as other group for debugging;
proc print data=WORK._Y6_FINAL;
run;
%abort 255;
*/

/*
proc print data=final(obs=50);run;
%abort 255;
*/

data final;
merge final x1(where=(&yval_var>=0) keep=old_y pos &yval_var &grp_var &scatter_grp_var &lattice_subgrp_var);
*Add back these excluded data;
run;
*Asign a specific values for gene with missing value;
proc sql noprint;
select grp1 into: genenames separated by " "
from 
(select unique(grp1)
from final
where grp1^="" and &yval_var.1<0);
%let onegenename=%scan(&genenames,1,%str( ));
%put selected genename for missing value is &onegenename;

*Asign a specific values for non-gene grp with missing value;
proc sql noprint;
select &grp_var into: grpnames separated by " "
from 
(select unique(&grp_var)
from x1
where &yval_var>=0);
%let onegrpname=%scan(&grpnames,1,%str( ));
%put selected grpname for missing value of non-gene group is &onegrpname;

data final;
set final;
array C{*} _character_;
do ci=1 to dim(C);
   grpname=vname(C{ci});
			*The &grp_var.1 to &grp_var.&tot_genegrps are for genes, thus they are only needed to be replaced for missing values with genename!;
		 if ci<=&tot_genegrps then do;
       if C{ci}="" then C{ci}="&onegenename";
				end;
				*For non-gene grps, use non-gene grp name to fill missing grp value;
				*This is not right, need to use gene name to fill all missing subgrps;
				*Because all sub grps &grp_var&i only contain gene or exon bed regions;
				else do;
/* 					if C{ci}="" then C{ci}="&onegrpname"; */
					if C{ci}="" then C{ci}="&onegenename";
				end;
end;
/*array N{*} _numeric_;*/
/*Can not asign values to numeric variable with missing values;*/
/* do ni=1 to dim(N); */
/*    if N{ni}=. then N{ni}=.; */
/* end; */
drop ci;
run;

*prevent missing data draw in the final scatterplot legend;
*Here would be a potential bug if the var lattice_subgrp_var is character;
*Address it by checking var type;
%check_var_type(
dsdin=final,
var_rgx=&lattice_subgrp_var
);
%put lattice_subgrp_var &lattice_subgrp_var variable type is &var_type;

%if %length(&lattice_subgrp_var)=0 %then %do;
  %put The lattice_subgrp_var is empty;
  %abort 255;
%end;

*For numeric lattice_subgrp_var;
%if %eval(&var_type=1) %then %do;
data _null_;
set final(keep=&lattice_subgrp_var where=(&lattice_subgrp_var^=.));
if _n_=1 then do;
  call symputx('lattice_grp1',&lattice_subgrp_var);
end;
else do;
		stop;
end;
run;

*To rescue the above when not drawing scatterplot, the macro var lattice_grp1 would be missing;
%if (&NotDrawScatterPlot=1) %then %let lattice_grp1=0;

data final;
set final;
if &lattice_subgrp_var=. then &lattice_subgrp_var=&lattice_grp1;
run;
%end;
%else %do;
*For character lattice_subgrp_var;
data _null_;
set final(keep=&lattice_subgrp_var where=(&lattice_subgrp_var^=""));
if _n_=1 then do;
  call symputx('lattice_grp1',&lattice_subgrp_var);
end;
else do;
		stop;
end;
run;
data final;
set final;
if &lattice_subgrp_var="" then &lattice_subgrp_var=&lattice_grp1;
run;

%end;

/*
proc print data=final(obs=50);run;
%abort 255;
*/

%if &add_grp_anno=1 %then %do;

***********************************Add grp label for making text identification*******************************;
/*proc print data=final;run;*/

data final(drop=A);
length grp_label $30.;
set final;
*Also need to add grp labels for the first grp, which usually represent genes for all grps;
*It is important to get the lag value of &grp_var.1 here;
*if use the lag function within the if else condition,;
*du to the _n_=1 was passed without of determine the 1st lag value,;
*the output is not as expected.;
A=lag(&grp_var.1);
if _n_=1 then do;
  grp_label=&grp_var.1;
end;
else do;
  if trim(&grp_var.1)^=trim(A) then grp_label=&grp_var.1;
  if pos1=. then grp_label=""; 
end;
*Adjust the y value to make the label about the left a little bit in the gene track;
*shift_text_yval can be negative or positve value;
if &yval_var.1^=. then _y_=&yval_var.1 + (&shift_text_yval*&pct4neg_y);

*adjust pos1 value if the xaxi_viewmin is set up;
%if %length(&xaxis_viewmin)>0 %then %do;
  if pos1<&xaxis_viewmin then pos1=&xaxis_viewmin;
%end;
run;

/*
proc print data=final(obs=50);run;
%abort 255;
*/

%end;


%if %length(&ordered_sc_grpnames)>0 and &NotDrawScatterPlot=0 %then %do;
    *Add a dataset containing scatterplot headers;
    *Note: scatter_grp_var should be in numeric;
    *Also adjust the x-axis position for the group headers;
    proc sql;
    create table header_dsd as
    select distinct 
    &scatter_grp_var as sc_grp, 
    &yval_var-(&adjval4header) as header_yval,avgpos
    from (select *, 
          0.5*(&max_x+&min_x) as avgpos 
          from x1)
    where &scatter_grp_var >0
    group by &scatter_grp_var
    having &yval_var=max(&yval_var);
    *Now get the scatter plot group names;
    %rank4grps(
    grps=&ordered_sc_grpnames,
    dsdout=scgrpnames
    );
    *Note: here all _ included in the name of scatter plot are changed into blank space;
    proc sql;
    create table header_dsd as
    select a.*,prxchange('s/_/ /',-1,b.grps) as header_grp
    from header_dsd as a,
         scgrpnames as b
    where a.sc_grp=b.num_grps;

    *Add the header dsd into the final dsd;
    *No need to adjust the avgpos by header length for each header grp;
    *SAS will adjust it automatically with the markercharacterposition=top in proc template;
    *But the code may be useful in adjusting gene labels;
/*     data header_dsd; */
/*     set header_dsd; */
/*     avgpos=avgpos*(1-0.005*(countc(header_grp))); */
/*     run; */
    data final;
    merge final header_dsd;
    run;
    *Get the minimum value of header_yval and the avgpos to fill these missing value after merge with final dsd;
    proc sql noprint;
    select header_yval, avgpos, header_grp 
     into: hd_min,:mid_pos,:hgrp
    from header_dsd
    group by sc_grp
    having sc_grp=min(sc_grp);
    data final;
    set final;
    if sc_grp=. then do;
     avgpos=&mid_pos;
     header_yval=&hd_min;
     header_grp="";
    end;
    run;
    /* proc print;run; */
%end;

*Get min and max postive old y value for heatmap;
proc sql noprint;
select floor(min(old_y)),ceil(max(old_y)) into: min_old_y,: max_old_y
from final(where=(old_y>=0));


*****************************************************************************************************************;
/*
proc export data=final outfile="final.txt" dbms=tab replace;
run;
*/

*documentation for adjusting axis for layout overlay;
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatug/p1pqfzgbuzbpkzn1mrbzhgggvhkz.htm;
*see line dash pattern here:;
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/p0er4dg9tojp05n1sf7maeqdz1d8.htm;
proc template;
define statgraph Bedgraph;
dynamic _chr _pos _value _G;
begingraph / designwidth=&track_width designheight=&track_height
       %*Use customized colors;
       %if %length(&dataContrastCols)>0 %then %do;
             dataContrastColors=( &dataContrastCols )
        %end;
        ;
 
 /*Define colors for dots by group in the scatter plot*/
 %if &lattice_subgrp_var ne %then %do;     
      discreteattrmap name="dotgrpname" / ignorecase=true;
        /*If the symbol is used in the scatterplot statment, the following symbol specification will be overwritten!*/
        value "Neg" /
          markerattrs=GraphData1(color=%scan(&scatterdotcols,1,%str( )) symbol=circlefilled)
          lineattrs=GraphData1(color=red pattern=solid);
        value "Pos" /
          markerattrs=GraphData2(color=%scan(&scatterdotcols,2,%str( )) symbol=trianglefilled)
          lineattrs=GraphData2(color=green pattern=shortdash);   
      enddiscreteattrmap;
      /*The attrvar and var have the same variable name here!*/
      discreteattrvar attrvar=&lattice_subgrp_var var=&lattice_subgrp_var
        attrmap="dotgrpname";
   %end; 
   
   %if &makedotheatmap=1 %then %do;
    /*Define colors for dots by group in the heatmap plot*/
      rangeattrmap name="dotheatmap";
         range &min_old_y - &max_old_y / 
         rangeAltColorModel=(CXFFFFB2 CXFED976 CXFEB24C CXFD8D3C CXFC4E2A CXE31A1C CXB10026);
         range OTHER / rangeAltColor=black;
         range MISSING / rangeAltColor=Lime;
       endrangeattrmap;
      /*The attrvar and var have the same variable name here!*/
      rangeattrvar attrvar=old_y_attrvar var=old_y
        attrmap="dotheatmap";
   
   %end;
        
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10 ;
         /*the offsetmin and offsetmax affect the offset area for y axis;*/
         layout overlay/yaxisopts=(
 /*                     only provide tickvalues will prevent other features, such as ticks, in the yaxis            */
/*                      need to add label to display y label; also remove ticks when makeheatmapdotintooneline=1   */
                        display=(%if &makeheatmapdotintooneline=0 %then %do; 
                                   tickvalues
                                 %end;
                                   label)
 /*                     type=linear offsetmin=0.05 offsetmax=0.05     */
                    %if &totsc>20 %then %do;
/*                         type=linear offsetmin=%sysevalf(&yaxis_offset4min*&totsc/200)  */
/*                         offsetmax=%sysevalf(&yaxis_offset4max*&totsc/200) */
/*                      The offset min and max will affect the upper and lower parts of the tracks   */
                        type=linear offsetmin=%sysevalf(&yaxis_offset4min*5/&totsc) 
                        offsetmax=%sysevalf(&yaxis_offset4max*5/&totsc)
                    %end;
                    %else %if &totsc>5 %then %do;
                        type=linear offsetmin=%sysevalf(&yaxis_offset4min*5/&totsc) 
                        offsetmax=%sysevalf(&yaxis_offset4max*5/&totsc)                    
                    %end;
                    %else %do;
                         type=linear offsetmin=&yaxis_offset4min 
                        offsetmax=&yaxis_offset4max                    
                    %end;
/*			linearopts=(minorticks=false tickvaluelist=(&y_axis_values) )      */
                        linearopts=(
                         %*expand the min and max value with 0.1 when only drawing gene track;
                         %if &NotDrawScatterPlot=1 %then %do;
                         %*it is hard to optimize;
                         viewmax=-&offsety viewmin=%sysevalf(&min_y-&&offsety)
                         %end;
                         %else %do;
/*                          viewmax=%sysevalf(&max_y+&offsety*2/&totsc) */
/*                          viewmin=%sysevalf(&min_y-&&offsety*2/&totsc) */
                         viewmax=%sysevalf(&max_y+0.1)
                         viewmin=%sysevalf(&min_y-0.1)                         
                         %end;
                         minorticks=false tickvaluelist=(&y_axis_values) tickdisplaylist=(&ylabelsmacro_var))
                        )
                        xaxisopts=(
                        linearopts=(
                        
                        %if %length(&xaxis_viewmin)>0 %then %do;
                        viewmin=&xaxis_viewmin
                        THRESHOLDMIN=0 
                        %end;
                        %else %do;
                        viewmin=&min_x
                        %end;
                        
                        %if %length(&xaxis_viewmax)>0 %then %do;
                        viewmax=&xaxis_viewmax
                        THRESHOLDMAX=0
                        %end;
                        %else %do;
                        viewmax=&max_x
                        %end;
                        
                        tickvalueformat=best32.) 
/*                      offsetmin=0.05 offsetmax=0.05       */
                        offsetmin=&xaxis_offset4min offsetmax=&xaxis_offset4max
                        );
                        /* Need to add this into linearopts later: tickdisplaylist=(&y_grp_values)*/
		 %do xti=1 %to %sysfunc(countw(&genegrp_ords));
      %let i=%scan(&genegrp_ords,&xti);
	       %if &i=1 %then %do;
                     *Add group labels, but failed due to text statement is not available for proc template;
                     *text x=&pos&i y=&yval_var.&i text=group_label;
                     *If the scatterplot is not wanted, we can exclude the reference line at 0;
                     %if %eval(&NotDrawScatterPlot=0) %then %do;
		              referenceline y=0 /lineattrs=(color=&refline_color pattern=1 thickness=&refline_thickness);
		             %end;     
						%if &min_y<0 %then %do;
/* 						  %do _yi_=&min_y %to -1; */
/* 		       referenceline y=&_yi_ /lineattrs=(color=black pattern=thindot thickness=1); */
/* 					          %end; */
                          %let _yneg_n=%eval(%sysfunc(countc(&yvals4reflines,%str( ))) + 1);
                          %do  _yneg_i=1 %to &_yneg_n;
                            *Do not draw reference line when NotDrawScatterPlot=1;
                            *Note: - is added before the number;
                            %if &NotDrawScatterPlot=0 %then %do;
                             %if &totsc<=5 %then %do;
                             referenceline y=-%scan(&yvals4reflines,&_yneg_i,%str( )) /lineattrs=(color=&refline_color pattern=thindot thickness=1);
                             %end;
                            %end;
                          %end;
						%end;
						
						
						%do yi=1 %to &max_y;
						    %if &totsc<=5 %then %do;
							 referenceline y=&yi /lineattrs=(color=&refline_color pattern=thindot thickness=1);
						    %end; 
						    *fix a bug when mk_fake_axis_with_updated_func=1 by getting rid of the last unwanted refline;
						    *also need to restrict it with %sysfunc(countw(&fake_refline_values))=2;
/* 						    %if (&mk_fake_axis_with_updated_func=1 and %sysfunc(countw(&fake_refline_values,ad))=1) %then  */
/* 						    %let fytot=%sysevalf(%sysfunc(countw(&fake_refline_values,ad)) - 0); */
/* 						    %else %let fytot=%sysfunc(countw(&fake_refline_values,ad)); */
/*                          The above uses countw without the modifiers ad for alphabetic and digital words will results in wrong result*/
                            %let fytot=%ntokens(&fake_refline_values);

						    %do xxi=1 %to &fytot;
                              %if &yi=%scan(&fake_refline_values,&xxi) %then %do;
		                         referenceline y=&yi /lineattrs=(color=&refline_color pattern=1 thickness=&refline_thickness);
		                         
							  %end;
						  %end;
						 %end;
		   %end;
					    *If the _y&i dsd dose not exist, skip it;
					    %if %sysfunc(exist(work._y&i)) %then %do;
									   %if %eval(&i=1) %then %do;
												 *make the 1str grp use group=&grp_var.&i and enable its color more transparent;
               seriesplot x=pos&i y=&yval_var.&i / group=&grp_var.&i connectorder=xaxis
                                      lineattrs=(pattern=SOLID thickness=&linethickness)
                                      name="series&i" datatransparency=0.5
												%end;
												%else %if (%eval(&i>=2)) %then %do;
												 *Make other grps use dark color, but it is not possible, as group is needed;
               seriesplot x=pos&i y=&yval_var.&i /connectorder=xaxis group=&grp_var.&i 
                                      lineattrs=(pattern=SOLID thickness=&linethickness)
                                      name="series&i" datatransparency=0.2

												%end;

          %end;                            
          ;
         %end;	
*Use &grp_var to color dots in scatterplot;         
/*          scatterplot x=pos y=&yval_var/group=&grp_var name="sc"  */
/*                                        markerattrs=( */
/*                                        symbol=circlefilled size=&dotsize  */
/*                                        ); */
*Use &scatter_grp_var to color dots in scatterplot;
*Failed, use &grp_var, again;
*Need to have a new group var &lattice_subgrp_var to color them;
 %if &makedotheatmap=1 %then %do;
*Note: the lattice_subgrp was used to determine whether to draw colorbar;
*the markercolorgradient will overwrite the symbol feature in markerattrs;
*filledoutlinedmarkers can be changed as true to add black dot outline;
*When choosing to draw dotheatmap;
*The group=&lattice_subgrp_var is not required!;
         scatterplot x=pos y=&yval_var/      
                                       markercolorgradient=old_y_attrvar
                                       filledoutlinedmarkers=false
                                       name="sc" 
                                       markerattrs=(
                                       symbol=circlefilled size=&dotsize
                                       );
       continuouslegend "sc"/title="scatter dot value";
 %end;
 %else %do;
         scatterplot x=pos y=&yval_var/ 
                                %if &lattice_subgrp_var ne %then %do;
                                       group=&lattice_subgrp_var
                                %end;
                                       name="sc" 
                                       markerattrs=(
                                       symbol=circlefilled size=&dotsize);
%end;                                       
                                       
       %if &add_grp_anno=1 %then %do;                              
         *Make sure to add the test label at the end, otherwise, these labels will be blocked by other layers;
         *MARKERCHARACTERPOSITION=CENTER | TOP | BOTTOM | LEFT | RIGHT | TOPLEFT | TOPRIGHT | BOTTOMLEFT | BOTTOMRIGHT;
/*         scatterplot x=pos1 y=&yval_var.1 / MARKERCHARACTER=grp_label MARKERCHARACTERPOSITION=left */
/*         use text customized y values to label these genes                                         */
         scatterplot x=pos1 y=_y_ / MARKERCHARACTER=grp_label MARKERCHARACTERPOSITION=topright
                                    MARKERCHARACTERATTRS=(color=black size=&grp_font_size 
                                    style=&grp_anno_font_type weight=normal);
       %end;
       
 %if %length(&ordered_sc_grpnames)>0 %then %do;      
       *Add scatter group header and adjust header x-axis position by length;
       scatterplot x=avgpos y=header_yval / markercharacter=header_grp 
       markercharacterattrs=(color=black size=%sysevalf(2+&grp_font_size)  weight=normal) 
       markercharacterposition=top;
  %end;     
      endlayout; 
	  sidebar /align=bottom;
			/*Note: only series1 is used to combine with sc in the discretelegend;
			  This is because seriesplot used the group options to draw all grps with
			  different colors in the 1st &grp_var1, which contain all gene grps;
			*/
 %if &makedotheatmap=1 %then %do;
      discretelegend "series1"
 %end;
 %else %do;
	  discretelegend "sc" "series1"
 %end;
/*   Only add legends for scatter plot and gene track*	  
/* 	  discretelegend "sc" %do i=1 %to &max_ord; */
/*                           "series&i" */
/*                          %end; */
          /border=false valueattrs=(color=black size=&grp_font_size weight=normal style=&grp_anno_font_type); 
	  endsidebar;
   endlayout;
endgraph;
end;
run;


*Change dir into the termporary work dir for saving svg figure;
%if &sysscp=WIN %then %do;
   %let workdir=%sysfunc(getoption(work));
%end;
%else %do;
   %let workdir=%sysfunc(pathname(HOME));
%end;

data _null_;
rc=dlgcdir("&workdir");
run;

%let outimagename=&yval_var.Chr%trim(%left(&chr_name))_&st_var%trim(%left(&min_x))_&end_var%trim(%left(&max_x));
%put The final figure is put here:;
%put &workdir/&outimagename..&fig_fmt;

ods graphics /
reset=all
outputfmt=&fig_fmt 
imagename="&outimagename" 
noborder;

*Add format for directions of &lattice_subgrp_var;
proc format;
value direction_fmt 0='Neg' 1='Pos';
run;

/*Does not work as expected;
ods graphics on/reset=all;
%ModStyle(
parent=journal,
colors=red blue green
);
*The above will generate the Newstyle;
ods html style=Newstyle;
*/

proc sgrender data=WORK.final template=BedGraph;
dynamic _chr="&chr_var";
format &lattice_subgrp_var direction_fmt.;
run;

*****************************************************************************************************************;
*Clean temporary datasets;
*Need to delete these _y: datasets, as there are used by the above proc template macro scripts;
%if &debug=0 %then %do;
proc datasets nolist;
delete _y: y1for:;
run;
%end;

%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

data x0;
*gscatter_grp can be either numeric numbers or charaters;
*the var cnv should be negative for gene grp;
input chr st end cnv grp $ gscatter_grp lattice_subgrp;
*gene X1: ranges from 100 to 1500, with 4 exons;
*gene agene: ranges from 2000 to 3000, with 5 exons;
*A good method is to increase scatterplot y values to enlarge scatterplot relatively to gene tracks;
*if cnv>0 then cnv=4*cnv;
cards;
1 200 300 -2 X1 -1 1
1 400 500 -2 X1 -1 0
1 550 600 -2 X1 -1 1
1 900 1000 -2 X1 -1 1
1 100 1500 -2 X1 -1 0
1 60 61 0 a 1 0
1 100 101 1 a 1 0
1 200 201 3 a 1 1
1 400 401 0 b 2 1
1 600 601 2 b 2 0
1 700 701 2 c 3 0
1 2000 3000 -1 agene -1 0
1 2100 2200 -1 agene -1 0
1 2300 2400 -1 agene -1 0
1 2500 2600 -1 agene -1 0
1 2700 2800 -1 agene -1 0
1 2900 3000 -1 agene -1 0
;
run;
*Note: data used by scatterplot but not the gene track should have end-st=1;
*Otherwise, the sas script take a long time to optimize the final figure;

****These modificatio of y-axis have been included in the macro;
*Add the maximum y values for each scatter group;
*This will enable the scatter plots have the same y axis;
*proc sql;
*select max(cnv) into: maxy4scatter from x0;
*proc sort data=x0;
*by gscatter_grp;
*data xx;
*set x0;
*if last.gscatter_grp and cnv>0 then do;
* output;
* st=.;
* end=.;
* cnv=&maxy4scatter;
* output;
*end;
*else do;
* output;
*end;
*by gscatter_grp;
*run;
***********************************************************************;

*options mprint mlogic symbolgen;

*make the same grp have the same cnv value to draw regions of the same grp together;
*Note: changing ngrp value leads to the separation or combination of different regions to be draw in a same line;
*%char_grp_to_num_grp(dsdin=x0,grp_vars4sort=grp,descending_or_not=0,dsdout=x1,num_grp_output_name=ngrp);

*lattice_subgrp_var can be empty!;
*data x0;
*set x0;
*gscatter_grp=1;

*go into a dir, and figure will be saved here;
data _null_;
rc=dlgcdir("/home/cheng.zhong.shan/data");
put rc=;
run;

*Note that the xaix start and end values can be customized;
%Lattice_gscatter_over_bed_track(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
scatter_grp_var=gscatter_grp,
lattice_subgrp_var=lattice_subgrp,
yval_var=cnv,
yaxis_label=%str(-log10%(P%)),
linethickness=20,
track_width=1600,
track_height=600,
dist2st_and_end=0,
dotsize=8,
debug=1,
add_grp_anno=1,
grp_font_size=8,
grp_anno_font_type=italic,
shift_text_yval=0.2, 
yaxis_offset4min=0.025, 
yaxis_offset4max=0.025, 
xaxis_offset4min=0.01, 
xaxis_offset4max=0.01,
xaxis_viewmin=500,
xaxis_viewmax=1900,
fig_fmt=svg,
refline_thickness=10,
refline_color=lightblue,
pct4neg_y=0.8,
NotDrawScatterPlot=0,
makedotheatmap=0,
color_resp_var=,
makeheatmapdotintooneline=0,
mk_fake_axis_with_updated_func=1,
sameyaxis4scatter=1,
maxyvalue4truncat=16,
adjval4header=0,
ordered_sc_grpnames=a_a b_b c_c,          
scatterdotcols=green yellow, 
dataContrastCols=%str(green darkorange)
);

*draw colormap with real y-axis values;
%debug_macro;
%Lattice_gscatter_over_bed_track(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
scatter_grp_var=gscatter_grp,
lattice_subgrp_var=lattice_subgrp,
yval_var=cnv,
yaxis_label=%str(-log10%(P%)),
linethickness=20,
track_width=1600,
track_height=600,
dist2st_and_end=0,
dotsize=8,
debug=1,
add_grp_anno=1,
grp_font_size=8,
grp_anno_font_type=italic,
shift_text_yval=0.2, 
yaxis_offset4min=0.025, 
yaxis_offset4max=0.025, 
xaxis_offset4min=0.01, 
xaxis_offset4max=0.01,
fig_fmt=png,
refline_thickness=10,
refline_color=lightblue,
pct4neg_y=0.8,
NotDrawScatterPlot=0,
makedotheatmap=1,
color_resp_var=,
makeheatmapdotintooneline=1,
mk_fake_axis_with_updated_func=1,
sameyaxis4scatter=1,
maxyvalue4truncat=16,
adjval4header=0,
ordered_sc_grpnames=a_a b_b c_c,          
scatterdotcols=green yellow, 
dataContrastCols=%str(green darkorange)
);

*If only the gene track is needed;
*The macro will try to change the dataset by keeping only negative y axis values;
%Lattice_gscatter_over_bed_track(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
scatter_grp_var=gscatter_grp,
lattice_subgrp_var=lattice_subgrp,
yval_var=cnv,
yaxis_label=%str(-log10%(P%)),
linethickness=20,
track_width=800,
track_height=300,
dist2st_and_end=0,
dotsize=8,
debug=1,
add_grp_anno=1,
grp_font_size=8,
grp_anno_font_type=italic,
shift_text_yval=0.1, 
yaxis_offset4min=0.1, 
yaxis_offset4max=0.1, 
xaxis_offset4min=0.01, 
xaxis_offset4max=0.01,
fig_fmt=svg,
refline_thickness=10,
refline_color=lightblue,
pct4neg_y=0.8,
NotDrawScatterPlot=1,
mk_fake_axis_with_updated_func=1,
sameyaxis4scatter=1,
maxyvalue4truncat=16,
adjval4header=0,
ordered_sc_grpnames=a_a b_b c_c,          
scatterdotcols=green yellow, 
dataContrastCols=%str(green darkorange)
);


*/
