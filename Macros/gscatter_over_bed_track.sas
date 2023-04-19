%macro gscatter_over_bed_track(
bed_dsd,
chr_var,
st_var,
end_var,
grp_var,
scatter_grp_var,
yval_var,
yaxis_label=Group,
linethickness=20,
track_width=800,
track_height=400,
dist2st_and_end=0,
dotsize=10
);
%if &scatter_grp_var eq %then %do;
  %put Please provide the variable for scatter_grp_var, as it is empty!;
  %abort 255;
%end;
*A new numberic group, ord, is created in descending order;
*Note: it is important to sort the group by yval_var ascendingly;
*as the group order will be used to selected genes or non-gene groups for making scatter plot or gene track;
%number_rows_by_grp(dsdin=&bed_dsd,grp_var=&grp_var,num_var4sort=&yval_var,desending_or_not=0,dsdout=x1);
proc sql noprint;
select unique(&chr_var) into: chr_name
from x1;

data x1(keep=&chr_var pos &yval_var &grp_var ord st end &scatter_grp_var);
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
*replace negative values with empty, as these axis values are for genes;
%let y_axis_values=%sysfunc(prxchange(s/-\d+/ /,-1,&y_axis_values));
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

/*Need to fill these missing values with pair of non-missing values,
otherwise, the missing values will be a group that will be included 
in the legend in the final figure*/
*Can not Ssimplify the above process by using &tot_genegrps!;
*Do not use the following loop;
/* %do gi=1 %to &tot_genegrps; */
/* %do gi=1 %to &max_ord; */
%do gi=1 %to %sysfunc(countw(&genegrp_ords));
%let _gi_=%scan(&genegrp_ords,&gi);
data y&gi(keep=ord &grp_var&_gi_ pos&_gi_ &yval_var&_gi_);
*Only keep these y values <0 and the max y value for drawing bed track;
*Excluded data will be plotted via scatter plot;
set x2;
if ord=&_gi_ then do;
  &grp_var&_gi_=&grp_var;
  pos&_gi_=pos;
		label pos&_gi_="Position (bp) on chromosome &chr_name";
  &yval_var&_gi_=&yval_var;
		label &yval_var&_gi_="&yaxis_label";
  output;
end;
else do;
   *Missing values will be generated for ord not equal to &_gi_;
  /*grp_var may be numeric or char, 
   just use its original value here,
   will remove it later*/
  &grp_var&_gi_=&grp_var;
  pos&_gi_=.;
		label pos&_gi_="Position (bp) on chromosome &chr_name";
  &yval_var&_gi_=.;
		label &yval_var&_gi_="&yaxis_label";
  output;
end;
run;

/*proc sort data=y&_gi_;by &grp_var&_gi_ ord pos&_gi_;*/
/*run;*/

/*get the 1st two records without missing values,
which will be used for fill these missing values later*/
data y&_gi_._ y&_gi_._missing;
set y&_gi_;
if pos&_gi_^=. then output y&_gi_._;
else output y&_gi_._missing;
/*create the common var n with values of 1 or 2
for matching with non-missing values from y1_*/
run;

*If the y&_gi_ dsd is empty, delete it;
%delete_empty_dsd(dsd_in=work.y&_gi_._);
*Only if the dsd is not empty, run other command;
*Decide to skip the other processing if the y&_gi_ dsd was deleted;
%iscolallmissing(dsd=y&_gi_,colvar=pos&_gi_,outmacrovar=tot_missing);
%put &tot_missing;
/* %if %sysfunc(exist(work.y&_gi_._)) %then %do; */
%if "&tot_missing" eq "0" and %sysfunc(exist(work.y&_gi_._)) %then %do;
data y&_gi_._missing;
set y&_gi_._missing;
if mod(_n_,2)=0 then n=2;
else n=1;
/*Also get the 1st two non-missing values and 
label them with 1 and 2 for matching*/
data y&_gi_._1;
set y&_gi_._;
n=_n_;
if _n_<=2;
run;
proc sql;
create table y&_gi_._filled as
select a.n as n&_gi_, b.*
from y&_gi_._missing as a,
     y&_gi_._1 as b
where a.n=b.n;
/*merge y1_filled with y1_*/
data y&_gi_._final(drop=ord n);
set y&_gi_._filled(drop=n&_gi_) y&_gi_._;
run;
%end;
%end;

data final;
set
%do i=1 %to &max_ord;
 %if %sysfunc(exist(work.y&i._final)) %then %do;
    y&i._final
 %end;
%end;
;
data final;
merge final x1(where=(&yval_var>=0) keep=pos &yval_var &grp_var &scatter_grp_var);
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
				else do;
					if C{ci}="" then C{ci}="&onegrpname";
				end;
end;
/*array N{*} _numeric_;*/
/*Can not asign values to numeric variable with missing values;*/
/* do ni=1 to dim(N); */
/*    if N{ni}=. then N{ni}=.; */
/* end; */
drop ci;
run;
/*
proc export data=final outfile="final.txt" dbms=tab replace;
run;
*/

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
						%do yi=1 %to &max_y;
		        referenceline y=&yi /lineattrs=(color=black pattern=2 thickness=0.5);
				                %end;
		   %end;
					    *If the y&i dsd dose not exist, skip it;
					    %if %sysfunc(exist(work.y&i)) %then %do;
               seriesplot x=pos&i y=&yval_var.&i / group=&grp_var.&i connectorder=xaxis 
                                      lineattrs=(pattern=SOLID thickness=&linethickness)
                                      name="series&i" datatransparency=0.2
          %end;                            ;
         %end;	
         scatterplot x=pos y=&yval_var/group=&scatter_grp_var name="sc" 
                                       markerattrs=(
                                       symbol=circlefilled size=&dotsize 
                                       );
                                      
      endlayout; 
	  sidebar /align=bottom;
	  discretelegend "sc" "series1"
/*   Only add legends for scatter plot and gene track*	  
/* 	  discretelegend "sc" %do i=1 %to &max_ord; */
/*                           "series&i" */
/*                          %end; */
          /border=true; 
	  endsidebar;
   endlayout;
endgraph;
end;
run;
ods graphics /imagename="&yval_var.&chr_var.:&st_var.-&end_var.png";
proc sgrender data=WORK.final template=BedGraph;
dynamic _chr="&chr_var";
run;

%mend;

/*Demo:
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

data x0;
*gscatter_grp can be either numeric numbers or charaters;
input chr st end cnv grp $ gscatter_grp;
cards;
1 400 500 -2 X1 .
1 700 900 -2 X1 .
1 100 101 1 a 0
1 200 201 3 a 1
1 400 401 0 b 0
1 600 601 2 b 0
1 700 701 2 c 0
1 900 3000 -1 agene .
;
run;
*Note: data used by scatterplot but not the gene track should have end-st=1;
*Otherwise, the sas script take a long time to optimize the final figure;

*options mprint mlogic symbolgen;

*make the same grp have the same cnv value to draw regions of the same grp together;
*Note: changing ngrp value leads to the separation or combination of different regions to be draw in a same line;
*%char_grp_to_num_grp(dsdin=x0,grp_vars4sort=grp,descending_or_not=0,dsdout=x1,num_grp_output_name=ngrp);

%gscatter_over_bed_track(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
scatter_grp_var=gscatter_grp,
yval_var=cnv,
yaxis_label=%str(-log10%(P%)),
linethickness=20,
track_width=800,
track_height=400,
dist2st_and_end=0,
dotsize=10
);


*/
