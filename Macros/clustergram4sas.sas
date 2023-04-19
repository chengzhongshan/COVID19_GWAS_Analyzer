%macro clustergram4sas(
dsdin=_last_,
rowname_var=,/*the elements of rowname_var will be used to label heatmap columns*/
numeric_vars=_numeric_,/*These column-wide numeric vars will become row-wide in the heatmap*/
height=20,/*figure height in cm*/
width=24,/*figure width in cm*/
columnweights=0.15 0.85, /*figure 2 column ratio*/
rowweights=0.15 0.85, /*figure 2 row ratio*/
cluster_type=3        /*values are 0, 1, 2, and 3 for not clustering heatmap, 
                       clustering heatmap by column, row, and both*/
);


/*https://blogs.sas.com/content/graphicallyspeaking/2017/04/20/advanced-ods-graphics-steps-think-creating-graph/*/
/* ods trace on; */
*options mprint mlogic symbolgen;
/*
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue; 
*/

data x(keep=&rowname_var &numeric_vars);
set &dsdin;
/*Need to run this to rescue the inconsistency of column names*/
&rowname_var=compress(&rowname_var);
&rowname_var=prxchange('s/\.//',-1,&rowname_var);
*give missing value 0;
array t{*} _numeric_;
do i=1 to dim(t);
   if t{i}=. then t{i}=0;
end;
drop i;
run;

/*Remove duplicate rownames*/
/*do not use it here, as it will change order of var &rowname_var 
for the heatmap if user wants to use its original order*/
/*proc sort data=x nodupkeys;by &rowname_var;run;*/

/*prepare data for column-wide clustering*/
%if &cluster_type=1 or &cluster_type=3 %then %do;

proc cluster data=x method=complete plots(maxpoints=500) noprint
     pseudo outtree=yaxis_dendrogram(keep=_name_ _parent_ _height_);
   id &rowname_var;
run;
data yaxis_dendrogram;
  set yaxis_dendrogram;
  %Rename_Add_Prefix(_name_ _parent_ _height_, y);
run;

%end;


/*prepare dta for row-wide clustering*/
%if &cluster_type=2 or &cluster_type=3 %then %do;

proc transpose data=x out=x_trans(rename=(_name_=colnames) drop=_label_);
var _numeric_;
run;
proc cluster data=x_trans method=complete plots(maxpoints=500) noprint
     pseudo outtree=xaxis_dendrogram(keep=_name_ _parent_ _height_);
   id colnames;
run;
data xaxis_dendrogram;
  set xaxis_dendrogram;
  %Rename_Add_Prefix(_name_ _parent_ _height_, x);
run;
%end;

data heatmap (keep=row col dist);
length row col $20.;
set x;
array m{*} _numeric_;
row=&rowname_var;
do i=1 to dim(m);
 call vname(m[i],col);
 col=compress(col);
 col=prxchange('s/\.//',-1,col);
 Dist=m[i];
 output;
 end;
 run;

 data all;
 merge 
%if &cluster_type=1 or &cluster_type=3 %then %do;
 yaxis_dendrogram 
%end;
%if &cluster_type=2 or &cluster_type=3 %then %do;
 xaxis_dendrogram 
%end;
%if &cluster_type=0 or &cluster_type=3 %then %do;
 heatmap
%end;
;
run;

/* As we can remove these walldisplay in the figure, no need the following codes*/
/* show source of defualt style */
 
/*  *Make style to change axis color, which is the only way to update axis color; */
/*  add my own itemsore in front of the ods path */
/* ods path */
/*   (prepend) work.mytemplates (update) */
/* ; */
/* proc template; */
/*   source styles.default; */
/* run; */
/*  */
/* build my own style, only changing the color  */
/* proc template; */
/*   define style styles.greyLine; */
/*     parent=styles.htmlblue; */
/*    This control the axis label color */
/*     class GraphAxisLines / */
/*       contrastcolor = black */
/*       color = black */
/*     ; */
/*     class GraphValueText / */
/*       color = black */
/*     ; */
/*     This part control the axis line thickness */
/*        class GraphWalls / */
/*        linethickness = 0px */
/*        linestyle = 1 */
/*        frameborder = on */
/*        contrastcolor = white */
/*        backgroundcolor = white */
/*        color = white; */
/*     class GraphAxisLines / */
/*        tickdisplay = "outside" */
/*        linethickness = 0px */
/*        linestyle = 1 */
/*        contrastcolor = GraphColors('gaxis') */
/*        ; */
/*   end; */
/* run; */
/*  */
/* data _null_; */
/* rc=dlgcdir('/home/cheng.zhong.shan/data'); */
/* run; */
/* ods html file="sample.html" gpath="." style=styles.greyline; */


/*Note: make sure to let rowdata and columndata with union range*/
proc template;
   define statgraph HeatDendrogram;
      begingraph / designheight=&height.cm designwidth=&width.cm;
         layout lattice    / rowdatarange=union columndatarange=union
                             rows=2 columns=2 
                             columnweights=(&columnweights) rowweights=(&rowweights);
            layout overlay; entry ' '; endlayout;
            layout overlay / xaxisopts=(display=none) yaxisopts=(display=none)
                             walldisplay=none;
														%if &cluster_type=1 or &cluster_type=3 %then %do;
               dendrogram nodeID=y_name_ parentID=y_parent_ clusterheight=y_height_;
														%end;
														%else %do;
															entry ' ';
														%end;
            endlayout;
            layout overlay / xaxisopts=(display=none reverse=true)
                             yaxisopts=(display=none reverse=true) walldisplay=none;
														%if &cluster_type=2 or &cluster_type=3 %then %do;
               dendrogram nodeID=x_name_ parentID=x_parent_ clusterheight=x_height_ /
                             orient=horizontal ;
														%end;
														%else %do;
															entry ' ';
														%end;
            endlayout;
            layout overlay / yaxisopts=(display=none reverse=true
                                        displaysecondary=(tickvalues))
                             xaxisopts=(display=(tickvalues)) walldisplay=none;
               heatmapparm y=col x=row colorresponse=dist/
                             colormodel=(cxFAFBFE cx667FA2 cxD05B5B) name="ht";
               continuouslegend "ht";
            endlayout;
         endlayout;
     endgraph;
   end;
run;
proc sgrender data=all template=HeatDendrogram;
run;

/* ods html close; */

%mend;

/*Demo:

*Make sure the input table have a column for rowname_var;
*which will be used as column-wide labels in the final heatmap;
 
%clustergram4sas(
dsdin=sashelp.baseball,
rowname_var=team,
numeric_vars=_numeric_,
height=20,
width=24,
columnweights=0.15 0.85, 
rowweights=0.15 0.85,
cluster_type=1 
);

*Note: if only sorting by column with the var rowname_var,;
*it is also possible to sort the _numeric_ vars row-wide in;
*in the heatmap by sorting the _numeric_ columns in the table;
*with specific order using %pull_column;

data t1;
set sashelp.baseball;
keep team _numeric_;
run;
proc contents data=t1 noprint out=tc(keep=VARNUM name);
run;
*The vars have already been sorted by name;
proc sql noprint;
select name into: colvars separated by " "
from tc;
%pull_column(dsd=t1,dsdout=t2,cols2pull=&colvars);

*or manually input column orders;
%pull_column(dsd=t1,dsdout=t2,cols2pull=1 9-18 2-8);

*Now run it for clustering only with rowname_var for column-wide;

%clustergram4sas(
dsdin=t2,
rowname_var=team,
numeric_vars=_numeric_,
height=20,
width=24,
columnweights=0.01 0.99, 
rowweights=0.15 0.85,
cluster_type=1 
);


*Alternatively, if only sorting by row with all _numeric_ vars;
*it is also possible to sort the rowname_var with specific order;
*by labeling the elements of rowname_var with numbers to sort it;
*Use the same method as above for sorting heatmap row-wide!; 

data r1;
set sashelp.baseball;
keep team _numeric_;
run;

*Here the table val_table_ordered contains the var team and a rank var;
*which will be used to order the var team in the original table;
proc sql;
create table r1 as
select a.*
from r1 as a,
     val_table_ordered as b
where a.team=b.team
order by b.rank;
*or sort it simply by name;
proc sort data=r1 nodupkeys;by team;run;
*Now run it for clustering only with rowname_var for row-wide;
%clustergram4sas(
dsdin=r1,
rowname_var=team,
numeric_vars=_numeric_,
height=20,
width=24,
columnweights=0.1 0.9, 
rowweights=0.15 0.85,
cluster_type=2 
);

*/
