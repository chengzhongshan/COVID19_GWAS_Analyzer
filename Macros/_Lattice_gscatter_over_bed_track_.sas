%macro Lattice_gscatter_over_bed_track_(
bed_dsd,/*Too many bed regions (>1000) for the gene track will slow down the macro dramatically*/
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
shift_text_yval=0.2, /*add positive or negative vale, rangin from 0 to 1, to liftup or lower text labels on the y axis*/
yaxis_offset4min=0.025, /*provide 0-1 value or auto to offset the min of the yaxis*/
yaxis_offset4max=0.025, /*provide 0-1 value or auto or to offset the max of the yaxis*/
xaxis_offset4min=0.01, /*provide 0-1 value or auto  to offset the min of the xaxis*/
xaxis_offset4max=0.01, /*provide 0-1 value or auto to offset the max of the xaxis*/
fig_fmt=svg /*output figure formats: svg, png, jpg, and others*/
);
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
run;
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
%make_fake_axis_values4grps(
dsdin=x1,
axis_var=&yval_var,
axis_grp=&scatter_grp_var,
new_fake_axis_var=&yval_var._new,
dsdout=x1,
yaxis_macro_labels=ylabelsmacro_var
);


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
proc sql noprint;
select &yval_var-1 into: fake_y_axis_vals separated by " "
from x1
where &yval_var>0 and grp_end_tag=1;
%put fake y axis values are &fake_y_axis_vals;

data x1(keep=&chr_var pos &yval_var &grp_var ord st end &scatter_grp_var &lattice_subgrp_var);
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

*Only keep records with yval_var <0 and the max y value;
*Exlude other data will prevent them from drawing in the bed track;
*These excluded data will be plotted with scatterplot;
data x2;
/* set x1(where=(&yval_var<0 or &yval_var=&max_y)); */
set x1(where=(&yval_var<0));
run;

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
%let ylabelsmacro_var=%sysfunc(prxchange(s/-\d+/ /,-1,&ylabelsmacro_var));

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

%do gi=1 %to %sysfunc(countw(&genegrp_ords));
%let _gi_=%scan(&genegrp_ords,&gi);
data _y&gi(keep=ord &grp_var&_gi_ pos&_gi_ &yval_var&_gi_);
*Only keep these y values <0 and the max y value for drawing bed track;
*Excluded data will be plotted via scatter plot;
set x2;
*Important to asign enough length for these grps, which are typical for gene names;
length  &grp_var&_gi_ $30.;
if ord=&_gi_ then do;
  &grp_var&_gi_=&grp_var;
  pos&_gi_=pos;
		label pos&_gi_="Position (bp) on chromosome &chr_name";
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
merge final x1(where=(&yval_var>=0) keep=pos &yval_var &grp_var &scatter_grp_var &lattice_subgrp_var);
*Add back these excluded data;
run;
*Asign a specific values for gene with missing value;
proc sql noprint;
select grp1 into: genenames separated by " "
from 
(select unique(grp1)
from final
where grp1^="" and &yval_var.1<0);
%let onegenename=%scan(&genenames,1);
%put selected genename for missing value is &onegenename;

*Asign a specific values for non-gene grp with missing value;
proc sql noprint;
select &grp_var into: grpnames separated by " "
from 
(select unique(&grp_var)
from x1
where &yval_var>=0);
%let onegrpname=%scan(&grpnames,1);
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
if &yval_var.1^=. then _y_=&yval_var.1 + (&shift_text_yval);
run;

/*
proc print data=final(obs=50);run;
%abort 255;
*/

%end;

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
begingraph / designwidth=&track_width designheight=&track_height;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10 ;
         /*the offsetmin and offsetmax affect the offset area for y axis;*/
         layout overlay/yaxisopts=(
 /*                     type=linear offsetmin=0.05 offsetmax=0.05     */
                        type=linear offsetmin=&yaxis_offset4min offsetmax=&yaxis_offset4max
/*			linearopts=(minorticks=false tickvaluelist=(&y_axis_values) )      */
                        linearopts=(minorticks=false tickvaluelist=(&y_axis_values) tickdisplaylist=(&ylabelsmacro_var))
                        )
                        xaxisopts=(
                        linearopts=(viewmin=&min_x viewmax=&max_x) 
/*                      offsetmin=0.05 offsetmax=0.05       */
                        offsetmin=&xaxis_offset4min offsetmax=&xaxis_offset4max
                        );
                        /* Need to add this into linearopts later: tickdisplaylist=(&y_grp_values)*/
		 %do xti=1 %to %sysfunc(countw(&genegrp_ords));
      %let i=%scan(&genegrp_ords,&xti);
	       %if &i=1 %then %do;
                     *Add group labels, but failed due to text statement is not available for proc template;
                     *text x=&pos&i y=&yval_var.&i text=group_label;
                      
		     referenceline y=0 /lineattrs=(color=black pattern=1 thickness=2);
						%if &min_y<0 %then %do;
						  %do _yi_=&min_y %to -1;
		       referenceline y=&_yi_ /lineattrs=(color=black pattern=thindot thickness=1);
					          %end;
						%end;
						%do yi=1 %to &max_y;
										referenceline y=&yi /lineattrs=(color=black pattern=thindot thickness=1);
						    %do xxi=1 %to %sysfunc(countw(&fake_refline_values));
               %if &yi=%scan(&fake_refline_values,&xxi) %then %do;
		             referenceline y=&yi /lineattrs=(color=black pattern=1 thickness=2);
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
         scatterplot x=pos y=&yval_var/ 
                                %if &lattice_subgrp_var ne %then %do;
                                       group=&lattice_subgrp_var
                                %end;
                                       name="sc" 
                                       markerattrs=(
                                       symbol=circlefilled size=&dotsize 
       %if &add_grp_anno=1 %then %do;                                  );
         *Make sure to add the test label at the end, otherwise, these labels will be blocked by other layers;
         *MARKERCHARACTERPOSITION=CENTER | TOP | BOTTOM | LEFT | RIGHT | TOPLEFT | TOPRIGHT | BOTTOMLEFT | BOTTOMRIGHT;
/*         scatterplot x=pos1 y=&yval_var.1 / MARKERCHARACTER=grp_label MARKERCHARACTERPOSITION=left */
/*         use text customized y values to label these genes                                         */
         scatterplot x=pos1 y=_y_ / MARKERCHARACTER=grp_label MARKERCHARACTERPOSITION=topright
                                            MARKERCHARACTERATTRS=(color=black size=&grp_font_size style=&grp_anno_font_type weight=normal);
       %end;
                               
      endlayout; 
	  sidebar /align=bottom;
			/*Note: only series1 is used to combine with sc in the discretelegend;
			  This is because seriesplot used the group options to draw all grps with
			  different colors in the 1st &grp_var1, which contain all gene grps;
			*/
	  discretelegend "sc" "series1"
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

ods graphics /
reset=all
outputfmt=&fig_fmt 
imagename="&yval_var._ChrRange_%trim(%left(&chr_name))._&st_var._%trim(%left(&min_x))._&end_var._%trim(%left(&max_x))" 
noborder;

*Add format for directions of &lattice_subgrp_var;
proc format;
value direction_fmt 0='Neg' 1='Pos';
run;


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
cards;
1 200 300 -2 X1 -1 1
1 400 500 -2 X1 -1 0
1 550 600 -2 X1 -1 1
1 900 1000 -2 X1 -1 1
1 100 1500 -2 X1 -1 0
1 100 101 1 a 1 0
1 200 201 3 b 1 1
1 400 401 0 b 2 1
1 600 601 2 a 2 0
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

*options mprint mlogic symbolgen;

*make the same grp have the same cnv value to draw regions of the same grp together;
*Note: changing ngrp value leads to the separation or combination of different regions to be draw in a same line;
*%char_grp_to_num_grp(dsdin=x0,grp_vars4sort=grp,descending_or_not=0,dsdout=x1,num_grp_output_name=ngrp);

*lattice_subgrp_var can be empty!;

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
fig_fmt=svg
);

*/
