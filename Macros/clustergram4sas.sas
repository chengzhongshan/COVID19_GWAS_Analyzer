%macro clustergram4sas(
/*The final rowlabels of the heatmap can be customized 
when not clustering the final rowlabels by
pre-sorting the numeric_var names with two macros: 
check_col_orders and pull_column
*/
dsdin=_last_,/*The input dataset is a matrix contains rownames and other numeric columns*/
rowname_var=,/*the elements of rowname_var will be used to label heatmap columns*/
numeric_vars=_numeric_,/*These column-wide numeric vars will become row-wide in the heatmap*/
height=20,/*figure height in cm*/
width=24,/*figure width in cm*/
columnweights=0.15 0.85, /*figure 2 column ratio*/
rowweights=0.15 0.85, /*figure 2 row ratio*/
cluster_type=3,        /*values are 0, 1, 2, and 3 for not clustering heatmap, 
                       clustering heatmap by column, row, and both*/
missing_value=-1,/*If assigning . to the missing_value, the macro will fail to generate dendrogram!
Assign specific numberic value to missing cell in the heatmap; default is to use ., 
as missing value will be assigned with different color; Note: assign negative value for missing data 
will draw the missing color at the bottom of colorbar*/
outputfmt=png,
colormodel=cxFAFBFE cx667FA2 cxD05B5B,
/*CXFFFFFF CXFFFFB2 CXFECC5C CXFD8D3C CXE31A1C */
/*Default WhiteYeOrRed colors for colormap; 
alternative colors: cxFAFBFE cx667FA2 cxD05B5B
Note: if rangemap_setting is not empty, colormodel will not be used!*/
rangemap_setting=,
/*If colormodel is EMPTY and rangemap_setting is not EMPTY, the macro will use rangemap setting for colorbar;
The following is an example code, and ensure the attrvar is named as RangeVar and Var equal to dist, 
which are hardcoded internally in the macro:
*Add more customized ranges to be labeled in the final colorbar!;
rangemap_setting=%str(
rangeattrmap name="ResponseRange";
        range min-300 / rangeColorModel=(CXFFFFB2 CXFED976 CXFEB24C CXFD8D3C CXFC4E2A CXE31A1C CXB10026);
        range OTHER   / rangeColorModel=(Gray);   
        range MISSING / rangeColorModel=(Lime);   
endrangeattrmap;
rangeattrvar var=dist                        
attrmap="ht"       
attrvar=RangeVar;  
)    
*/
continuouslegend_setting=
%nrstr(location=outside valign=bottom halign=center integer=false valuecounthint=50),
/*Change the colorbar setting; If left empty, default setting will be applied by sas;
Note: if rangemap_setting is used, sas assumes the colorbar will be discreted and the continuouslegend_setting will fail!;*/
heatmap_dsd=longformat_heatmap_dsd /*Output a copy dataset that is used for making the heatmap, which can be modified 
to make updated heatmap with the GTL template HeatDendrogram as follows:
data longformat_heatmap;
set longformat_heatmap;
ord=_n_;
run;
*Modify the longformat_heatmap and keep its row order by sorting with ord;
data tgt;
set longform_heatmap;
*Your codes to modify the color variable Dist;
run;
proc sgrender data=tgt template=HeatDendrogram;
run;
*/
);


/*https://blogs.sas.com/content/graphicallyspeaking/2017/04/20/advanced-ods-graphics-steps-think-creating-graph/*/
/* ods trace on; */
*options mprint mlogic symbolgen;
/*
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue; 
*/

*Keep unique rownames;
proc sort data=&dsdin out=x nodupkeys;by &rowname_var;run;

data x(keep=&rowname_var &numeric_vars);
set x;
/*Need to run this to rescue the inconsistency of column names*/
&rowname_var=compress(&rowname_var);
&rowname_var=prxchange('s/\.//',-1,&rowname_var);
*give missing value 0;
%if %length(&missing_value)>0 %then %do;
array t{*} _numeric_;
do i=1 to dim(t);
   if t{i}=. then t{i}=&missing_value;
end;
drop i;
%end;
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

proc transpose data=x out=x_trans(rename=(_name_=colnames));
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
length row col $100.;
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
 merge heatmap 
%if &cluster_type=1 or &cluster_type=3 %then %do;
 yaxis_dendrogram 
%end;
%if &cluster_type=2 or &cluster_type=3 %then %do;
 xaxis_dendrogram 
%end;
%if &cluster_type=0 or &cluster_type=3 %then %do;
 
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
%let rnd=%RandBetween(1,1000);
ods graphics /reset=all noborder outputfmt=&outputfmt imagename="Clustergram_random&rnd";
*The above failed sometimes due to unknown reasons;
*It is necessary to remove previous setting;
proc template;
   define statgraph HeatDendrogram;
      begingraph / designheight=&height.cm designwidth=&width.cm;
        %if %length(&rangemap_setting)>0 %then %do;
              &rangemap_setting;  
         %end;

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
            *To remove outline, add "walldisplay=none";
            layout overlay / walldisplay=none yaxisopts=(display=none reverse=true
                                        displaysecondary=(tickvalues))
                             xaxisopts=(display=(tickvalues));
               heatmapparm y=col x=row 
                               %if %length(&rangemap_setting)>0 %then %do;
                                colorresponse=RangeVar/
                                %end;
                                %else %do;
                                colorresponse=dist/colormodel=(&colormodel)  
                                 %end;
                                name="ht" outlineattrs=(color=gray  thickness=1) display=all;
               *The above codes of outlineattrs=(color=gray  thickness=1) display=all customize grid colors and thickness;

               *Customize the colorbar ticks;
               *Although the suggested tick counts is 50, sas will automatically decide how many integers will be used for ticks;
               *default value: location=outside valign=bottom halign=center valuecounthint=50;
               continuouslegend "ht" / &continuouslegend_setting;
            endlayout;
         endlayout;
     endgraph;
   end;
run;

*Need to exclude missing values;
proc sgrender data=all template=HeatDendrogram;
run;

*The above colormodel can be updated by using %colormac;
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/graphref/p0d4brn7o50u8ln1xxolln8t7tvc.htm;
*such as %RBG(100,100,0) for the yellow color;


/* ods html close; */

*Keep a copy of the final transformed dataset;
data &heatmap_dsd;
set all;
run;

%mend;

/*Demo:

data a;
input a $ b $ c;
*c=log2(c);
cards;
a1 b1 100
a1 b2 200
a2 b1 300
a3 b3 400
;
%debug_macro;
*Macro var annotations:;
*dsdin: The input dataset is a matrix contains rownames and other numeric columns;
*rowname_var: the elements of rowname_var will be used to label heatmap columns;
*colname_var: These column-wide names will be used to label heatmap rowlabels;
*value_var: numeric data for heatmap cells;
*height: figure 2 height in cm;
*width: figure 2 width in cm;
*columnweights: figure 2 column ratio;
*rowweights: figure 2 row ratio;
*cluster_type: values are 0, 1, 2, and 3 for not clustering heatmap clustering heatmap by column, row, and both;
*This is just for comparison!;
%clustergram4longformatdsd(
dsdin=a,
rowname_var=a,
colname_var=b,
value_var=c,
height=8,
width=10,
columnweights=0.15 0.85, 
rowweights=0.15 0.85, 
cluster_type=3
);

*************************Optimized demo codes for clustergram4sas*****************************;
*Now use the macro clustergram4sas with customized axis order;
proc sort data=a;by a b;run;
proc transpose data=a out=a_trans(drop=_name_);
var c;
id b;
by a;
run;
proc print;run;
*It is important here not to cluster the heatmap by row or both of row and column;
%debug_macro;
%pull_column(dsd=a_trans,dsdout=a_trans1,cols2pull=1 3 2 4);
proc print data=a_trans1;run;

*Note: if rangemap_setting is used, sas assumes the colorbar will be discreted and the continuouslegend_setting will fail!;

%clustergram4sas(
dsdin=a_trans1,
rowname_var=a,
numeric_vars=_numeric_,
height=10,
width=14,
columnweights=0.15 0.85, 
rowweights=0.15 0.85, 
cluster_type=1,
missing_value=-100,
outputfmt=png,
colormodel=,
rangemap_setting=%str(
rangeattrmap name="ResponseRange";
        range 0 - 200 / rangeColorModel=(CXFFFFB2 CXFED976 CXFEB24C CXFD8D3C CXFC4E2A CXE31A1C CXB10026);
        range 200 - 300 /rangeColorModel=(green darkred);
        range 300 - max /rangeColorModel=(darkred blue);
        range -100 - 0   / rangeColorModel=(lightgrey); 
        range other / rangeColorModel=(black);  
        range MISSING / rangeColorModel=(lime);   
endrangeattrmap;
rangeattrvar var=dist                        
attrmap="ResponseRange"       
attrvar=RangeVar;  
),
continuouslegend_setting=%nrstr(location=outside valign=bottom halign=center valuecounthint=100),
heatmap_dsd=longformat_heatmap_dsd         
);


***********************Other good demo codes************************************;
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
