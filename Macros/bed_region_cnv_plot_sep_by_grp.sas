%macro bed_region_cnv_plot_sep_by_grp(bed_dsd,chr_var,st_var,end_var,grp_var,cnv_var,linethickness=20);
/*Note: this macro will create a var ord for making seriesplot and color each bed regions by the 
macro var grp_var. The limitation is that each bed region will be 
plotted separatedly among different subplots via the datalattice procedure!*/


/*asign row numbers by macro var &grp_var and &str_var*/
/*It is important to combine the st pos and grp_var as a single key and
generate numberic grps for these keys, i.e., 1, 2, and other numbers.
A bug for this step is that some bed regions with the same start pos will
be only kept for one record!*/
/*%number_rows_by_grp(dsdin=&bed_dsd,grp_var=&grp_var,num_var4sort=&st_var,desending_or_not=0,dsdout=x1);*/

/*The following step will number all bed regions by using &grp_var, &st_var, and &end_var;*/
data x1;
set &bed_dsd;
proc sort data=x1;by &grp_var &st_var &end_var;
run;
data x1;
set x1;
if first.&end_var then do;
 ord=1;
end;
else do;
 ord+1;
end;
run;

/*It is necessary to put st and end positions into separated rows and labeled with 1 and 2,
which will be used by seriesplot!*/
data x1(keep=&chr_var pos &cnv_var &grp_var ord);
set x1;
array X{2} &st_var &end_var;
do i=1 to 2;
 pos=X{i};
 output;
end;
run;

/*Get max grp number for split data into different dsd*/;
proc sql noprint;
select max(ord)*150 into: max_height
from x1;

/*Create a var to make the datalabel for the end position but not the start position*/
data x1;
set x1;
endlabel=&grp_var;
if mod(_n_,2)^=0 then endlabel="";
run;

proc template;
define statgraph Bedgraph;
dynamic _chr _pos _value _G;
/*Need to adjust width and height for different data*/
begingraph / designwidth=800 designheight=&max_height;
   /*Make sure to use ord to separated data for seriesplot*/
   layout datalattice rowvar=ord / 
                             headerlabeldisplay=none 
                             columnaxisopts=(griddisplay=on)
                             rowaxisopts=(griddisplay=on);
         layout prototype;
/*		     referenceline y=0 /lineattrs=(color=black pattern=1 thickness=2);*/
/*		     referenceline y=1 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=-1 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=-2 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=2 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=-3 /lineattrs=(color=black pattern=2 thickness=0.5);*/
/*		     referenceline y=3 /lineattrs=(color=black pattern=2 thickness=0.5);*/

			 /*Here the group var is important to plot lines correctly*/
             seriesplot x=_pos y=_value / group=_G connectorder=xaxis datalabel=endlabel datalabelattrs=(size=15)
                                      lineattrs=(pattern=SOLID thickness=&linethickness)
                               		  name="series"
                                      ;
      endlayout; 
	  sidebar /align=bottom;
	  discretelegend "series"; 
	  endsidebar;
   endlayout;
endgraph;
end;
run;

/*This will disable label collision*/
ods graphics / reset labelmax=0;

proc sgrender data=WORK.x1 template=BedGraph;
dynamic _chr="&chr_var" _G="&grp_var" _Pos="Pos" _value="&cnv_var" ;
run;

%mend;

/*Demo:

data x0;
input chr st end cnv grp $;
cards;
1 100 300 1 x1
1 200 400 3 x1
1 400 500 0 x2
1 600 800 3 x2
1 700 800 5 x2
;
run;

options mprint mlogic symbolgen;

%bed_region_cnv_plot_sep_by_grp(
bed_dsd=x0,
chr_var=chr,
st_var=st,
end_var=end,
grp_var=grp,
cnv_var=cnv,
linethickness=20
);


*/
