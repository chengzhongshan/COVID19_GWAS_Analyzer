%macro Beta2OR_forest_plot(
dsdin=,
beta_var=,
se_var=,
sig_p_var=,/*adjust the threshold of p in the extra_condition4updatedsd*/
marker_var=,
marker_label=,
svgoutname=,
figfmt=png,
figwidth=600,
figheight=800,
dotsize=10,
autolegend=0,
xaxis_value_range=%str(0.4 to 1.6 by 0.2),
sort_var4y=,/*Provide a variable in the input dsdin to sort the y axis tickets in the final figure;
1. If left empty, it will use the default data order of marker_var to label y-axis from lower to upper;
The default order of data can be modified by using proc sort procedure as follows:
proc sort data=tops;by type gwas2_beta rsid;run;
This is powerful because multiple variables can be used to sort the final y-axis tickets;
2. Alternatively, it is fine to use a new variable, as sometimes it is better to create 
a new variable for sorting the input dsdin before applying the current macro
*/
y2axis_ticket_var=,/*Default is emptyp to not to draw the 2nd yaxis;
Provide a variable name to use its values to draw the 2nd yaxis*/
both_y_font_size=12, /*Font size for any of the two y-axis*/
min_axis=0,
max_axis=2,
yoffsetmax=0.02, /*offset for the upper y axis maximum value*/
yoffsetmin=0.02, /*offset for the lower y axis minimum value*/
/*Note: the macro need to have a input variable grp to color dots representing OR;
So in the following extra condition for input dataset, a new variable grp is created.*/
extra_condition4updatedsd=%nrstr(
length sigtag $10.;
if &marker_var="rs16831827" then do;
 grp=0;sigtag='';
end;
else if &sig_p_var<5e-8 then do;
 grp=1;sigtag='*';
end;
else do;
 grp=1;sigtag="";
end;
if &marker_var="12:113357193:G:A" then &marker_var="rs10774671";
if &marker_var="17:44219831:T:A" then &marker_var="rs1819040";
if &marker_var="19:10427721:T:A" then &marker_var="rs74956615";

if &marker_var in ('rs2271616','rs11919389','rs912805253','rs4801778') then grp=0;
else if &marker_var='rs16831827' then grp=1;
else grp=2;
 )
);


data tmp;
set &dsdin;
effect=exp(&beta_var);
uppercl=exp(&beta_var+1.96*&se_var);
lowercl=exp(&beta_var-1.96*&se_var);
%unquote(&extra_condition4updatedsd);
run;

options printerpath=(svg out) nobyline;
filename out "&svgoutname%RandBetween(1,100)..&figfmt";
ods listing close;
ods printer;

title "OR Forest Plot";
ods graphics on/reset=all noborder outputfmt=&figfmt
                            width=&figwidth height=&figheight
                            imagename="&svgoutname%RandBetween(1,100)";
data _tmp_;
set tmp;
keep by_n &marker_var;
%if %length(&sort_var4y)=0 %then %do;
   by_n=_n_;
%end;
%else %do;
  by_n=&sort_var4y;
%end;
run;

%mkfmt4grps_by_var(
grpdsd=_tmp_,
grp_var=&marker_var,
by_var=by_n,
outfmt4numgrps=x2y,
outfmt4chargrps=y2x
);

data tmp;
set tmp;
*format char grps to numeric grps;
new_grp_var=input(&marker_var,x2y.);
run;

***********Import attrmap to assign the same color schemes to different grp*****************************;
/*https://blogs.sas.com/content/iml/2017/01/30/auto-discrete-attr-map.html*/
%let VarName = grp;           /* specify name of grouping variable */
proc freq data=tmp ORDER=FORMATTED;   /* or ORDER=DATA|FREQ  */
   tables &VarName / out=Attrs(rename=(&VarName=Value));
run;
data DAttrs;
ID = "&VarName";                 /* or "ID_&VarName" */
set Attrs(keep=Value);
length MarkerStyleElement $11.;
MarkerStyleElement = cats("GraphData", 1+mod(_N_-1, 12)); /* GraphData1, GraphData2, etc */
run; 
/*proc print; run;*/
***********The above codes are important to assign the same color schemes to different grp*********;


proc sgplot data=tmp dattrmap=DAttrs %if &autolegend=0 %then noautolegend;;
/* scatter x=effect y=&marker_var / datalabel=sigtag */
scatter x=effect y=new_grp_var / datalabel=sigtag 
datalabelattrs=(size=&both_y_font_size) 
group=grp xerrorlower=lowercl  grouporder=ASCENDING attrid=grp
xerrorupper=uppercl	 name="dotsc"
markerattrs=(symbol=circleFilled size=&dotsize);
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/p0er4dg9tojp05n1sf7maeqdz1d8.htm;
refline 1 / axis=x lineattrs=(pattern=solid color=darkgray thickness=1) ;
xaxis label="OR and 95% CI " min=&min_axis valueattrs=(size=&both_y_font_size) max=&max_axis values=(&xaxis_value_range);
*It is necessary to add the type=discrete to fix the yaxis using the newly created new_grp_var with its numeric format;
yaxis label="&marker_label" valueattrs=(size=&both_y_font_size style=normal) type=discrete display=(nolabel)
          offsetmax=&yoffsetmax offsetmin=&yoffsetmin;

*Draw y2axis with a different variable used to label y2axis with italic font on the right;
*Note: the same x but different y variables are used to only draw dots by group;
%if %length(&y2axis_ticket_var)>0 %then %do;
*Note: decrease the dot size to minimum, as we only want the addition of y2axis;
scatter x=effect y=&y2axis_ticket_var /y2axis group=grp markerattrs=(symbol=circleFilled size=0.1) grouporder=ASCENDING attrid=grp;
y2axis valueattrs=(size=&both_y_font_size style=italic) type=discrete display=(nolabel noticks)           
            offsetmax=&yoffsetmax offsetmin=&yoffsetmin;
%end;

%if &autolegend=1 %then %do;
keylegend "dotsc"/ title="";
%end;

format new_grp_var y2x.;
run;
ods printer close;
ods listing;
title;

%mend;

/*Demo codes:;

libname D 'H:\Coorperator_projects\COVID_Papers_2023\HGI_NonHospitalizationGWASPaper';

data tops(drop=grp);
set D.tops;
type=grp;
run;
*lookup these SNPs with gene names and combine rsid and gene name as final y-axis tickets;
proc import datafile="E:\LongCOVID_HGI_GWAS\Multi_Long_GWAS_Integration\New_LongCOVID_GWAS_Publication_Materials2024\LongCOVID_Figures\top_snp2gene.csv"
dbms=csv out=snp2gene replace;
getnames=yes;guessingrows=max;
run;

*Not good to use combined rsid and gene name for labeling the y-axis;
*Just plot two yaxes using different labels;

proc sql;
create table tops as
select a.*,b.gene
from tops as a
left join 
snp2gene as b
on a.rsid=b.rsid;

*It is important to sort data by type and specific GWAS beta value;
*beta is best as it indicates positive or negative associations;
proc sort data=tops;by type gwas2_beta rsid;run;

*Draw forest plots for top hits for gwas1;
%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=gwas1_beta, 
se_var=gwas1_se, 
sig_p_var=gwas1_p,
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_B1, 
figfmt=png,
figwidth=900,
figheight=1400, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);

*Draw the same forest plots for top hits for gwas2;
*Note: similar legend and color setting will be used for gwas2;
*Thus the two plots can be combined manually in a PPT slide;
%Beta2OR_forest_plot( 
dsdin=tops, 
beta_var=gwas2_beta, 
se_var=gwas2_se, 
sig_p_var=gwas2_p,
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_B2, 
figfmt=png,
figwidth=900,
figheight=1400, 
autolegend=0,
dotsize=6, 
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
if type="Hosp" then do; 
grp=0;sigtag=''; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=1;sigtag='*'; 
end; 
end; 
else do; 
grp=2;sigtag=""; 
if &sig_p_var<5e-8 and &sig_p_var>0 then do; 
grp=3;sigtag='*'; 
end; 
end; 
) 
);

*/
