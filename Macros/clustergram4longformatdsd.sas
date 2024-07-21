%macro clustergram4longformatdsd(
/*The limitation of clustergram4longformatdsd compared to clustergram4sas
is that the orders of two axes of final heatmap is sorted by varnames if not clustered,
as this macro will sort the long format data by rowname_var and colname_var, and then
tranpose it for cluster if either one of them is subjected to clustering!
Thus please use clustergram4sas whenever it is possible;
see demos for clustergram4sas, which include all possible scenarios!
*/
dsdin=_last_,/*The input dataset is a matrix contains rownames and other numeric columns*/
rowname_var=,/*the elements of rowname_var will be used to label heatmap columns*/
colname_var=,/*These column-wide names will be used to label heatmap rowlabels*/
value_var=,/*numeric data for heatmap cells*/
height= ,/*figure height in cm, such as 20;
if empty, it will use the number of rownames * 0.8 as height*/
width= ,/*figure width in cm, such as 24;
if empty, it will use the number of colnames * 0.5 as width*/
columnweights=0.05 0.95, /*figure 2 column ratio*/
rowweights=0.15 0.85, /*figure 2 row ratio*/
cluster_type=3,        /*values are 0, 1, 2, and 3 for not clustering heatmap, 
                       clustering heatmap by column, row, and both*/
missing_value=-1,/*If assigning . to the missing_value, the macro will fail to generate dendrogram!
Assign specific numberic value to missing cell in the heatmap; default is to use -1, 
as missing value will be assigned with different color; Note: assign negative value for missing data 
will draw the missing color at the bottom of colorbar*/  
outputfmt=png, /*output figure formats: svg, jpg, png, and other sas ods supported figure formats*/  
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
%nrstr(location=outside valign=bottom halign=center integer=false valuecounthint=50 ),
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

*estimate the clustergram height and width by calculating total number of snpid and genegrp;
%if %length(&width)=0 %then %do;
*the elements of rowname_var will be used to label heatmap columns;
proc sql noprint;
select count(&rowname_var) into: totrows
from (select unique(&rowname_var) from &dsdin);
%let width=%sysevalf(&totrows*0.3,int);/*in cm*/
%end;

%if %length(&height)=0 %then %do;
*the elements of colname_var will be used to label heatmap rows;
proc sql noprint;
select count(&colname_var) into: totcols
from (select unique(&colname_var) from &dsdin);
%let height=%sysevalf(&totcols*1.1,int);/*same in cm*/
%end;

%put The clustergram size will be &height x &width (cm x cm);

/*https://blogs.sas.com/content/graphicallyspeaking/2017/04/20/advanced-ods-graphics-steps-think-creating-graph/*/
/* ods trace on; */
*options mprint mlogic symbolgen;
/*
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue; 
*/

*Keep unique rownames and colnames;
proc sort data=&dsdin out=_x_ nodupkeys;by &rowname_var &colname_var;run;
data _x_;
set _x_;
&rowname_var=prxchange('s/[\W\s]+/_/',-1,trim(left(&rowname_var)));
&colname_var=prxchange('s/[\W\s]+/_/',-1,trim(left(&colname_var)));

*Need to truncate the rowname_var and colname_var and enable their length <=32;
if length(&rowname_var)>=32 then &rowname_var=substr(&rowname_var,1,32);
if length(&colname_var)>=32 then &colname_var=substr(&colname_var,1,32);

*Further remove trailing char '_';
&rowname_var=prxchange('s/_\b//',-1,&rowname_var);
&colname_var=prxchange('s/_\b//',-1,&colname_var);
run;
/* %abort 255; */

*Now it is necessary to transpose the long format data into a table;
*The rowname_var will be the rownames;
*The colname_var will be transposed into column-wide;
*The value_var will be used for these new, numeric column vars;
proc transpose data=_x_ out=x;
var &value_var;
id &colname_var;
by &rowname_var;
run;

data x(keep=&rowname_var _numeric_);
set x;
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
*Ensure the row and col vars are no longer than 32 chars;
length row col $32.;
set x;
array m{*} _numeric_;
row=&rowname_var;
do i=1 to dim(m);
 call vname(m[i],col);
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

*remove _ from rownames and colnames for heatmap;
data all;
set all;
row=prxchange('s/_+/ /',-1,row);
col=prxchange('s/_+/ /',-1,col);
y_name_=prxchange('s/_+/ /',-1,y_name_);
x_name_=prxchange('s/_+/ /',-1,x_name_);
run;


/*Note: make sure to let rowdata and columndata with union range*/
ods graphics /reset=all noborder outputfmt=&outputfmt imagename="Clustergram_%RandBetween(1,100)";
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
            layout overlay / yaxisopts=(display=none reverse=true
                                        displaysecondary=(tickvalues))
                             xaxisopts=(display=(tickvalues));
               heatmapparm y=col x=row 
                               %if %length(&rangemap_setting)>0 %then %do;
                                colorresponse=RangeVar/
                                %end;
                                %else %do;
                                colorresponse=dist/colormodel=(&colormodel)  
                                 %end;
                                name="ht";
               *Customize the colorbar ticks;
               *Although the suggested tick counts is 50, sas will automatically decide how many integers will be used for ticks;
               *default value: location=outside valign=bottom halign=center valuecounthint=50;
               continuouslegend "ht" / &continuouslegend_setting;
            endlayout;
         endlayout;
     endgraph;
   end;
run;

proc sgrender data=all  template=HeatDendrogram;
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

*Use data from GTEx boxplot by grp macro;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;


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

%clustergram4longformatdsd(
dsdin=a,
rowname_var=a,
colname_var=b,
value_var=c,
height=8,
width=10,
columnweights=0.15 0.85, 
rowweights=0.15 0.85, 
cluster_type=3,
colormodel=,
missing_value=-100,
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


libname GTEX '/home/cheng.zhong.shan/data/GTEx_V8';

*Note: the input gene order will be used to draw boxplots from up to down;
%let genes=APOBEC3A APOBEC3B APOBEC3C APOBEC3D APOBEC3F APOBEC3G APOBEC3H;
*%let genes=MAP3K19 CXCR4;
data exp_all;set GTEX.target_genes;run;
data headers;set GTEX.headers;run;
*Use generated dataset exp_all or GTEX.target_genes;
*options mprint mlogic symbolgen;
*The macro is with bug, when using previously generated dsd;
*Need to asign dsdout exp_all and PreviousDsd as empty string;
*The bug is due to the macro var PreviousDsd is fixed to be 'tgt';
*So it is arbitary to asign macro var PreviousDsd as 'tgt' whenever using previous dsd;

%Boxplots4GenesInGTExV8ByGrps(
genes=&genes,
dsdout=exp_all,
bygrps=AA,
UseGeneratedDsd=1,
PreviousDsd=tgt,
Lib4PreviousDsd=work,
WhereFilters4Boxplot=%str( AA in ("AA","EA") and 
cluster in ("Whole Blood","Testis")),
boxplot_width=200,
boxplot_height=800
);

*the dataset tgt will be generated by the above macro;
proc print data=tgt(obs=10);run;
proc sql;
create table median_exp as
select distinct cluster,rownames,median(exp) as exp
from tgt
group by cluster,rownames;
proc print data=median_exp(obs=10);run;

%clustergram4longformatdsd(
dsdin=median_exp,
rowname_var=rownames,
colname_var=cluster,
value_var=exp,
height=35,
width=20,
columnweights=0.15 0.85, 
rowweights=0.05 0.95, 
cluster_type=2        
);

*/
