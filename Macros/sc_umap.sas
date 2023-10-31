%macro sc_umap(
umap_ds=umap,
xvar=x,
yvar=y,
cluster_var=cluster,
sample_grp_var=,
ordered_sample_grps=,/*Provide ordered group names here to generate subplots in the same order as in this macro var*/
down_sampling_num=1,/*
Provide pct value ranging from 0 to 1 or 
number of cells
to get random cells for down-sampling*/
fig_width=1400,
fig_height=800,
rowaxis_min=0,
rowaxis_max=,
colaxis_min=,
colaxis_max=,
where_condition4cells=%nrstr(), /*Add where condition to filter cell types*/
marker_size=2,/*scatter plot marker size; the smaller the better for large sc dataset*/
cell_label_size=12, /*text label font size for cell labels*/
fig_column_num4sample_grps=1 /*this value will be assigned to the columns in proc sgpanel;
when columns=1, the umaps for different sample groups will be put into a single column;
when columns=total_number_of_grps, the umaps will be put into a single row;
when columns (1,total_nummber_of_grps), the umaps will be put by columns and rows one by one!*/
);

data _UMAP_;
set &umap_ds;
run;
%if &down_sampling_num^=1 %then %do;
  %if &down_sampling_num>0 and &down_sampling_num<1 %then %do;
  proc sql noprint;
  select ceil(count(*)*&down_sampling_num) into: tot_sampled_cells from _UMAP_;
  %Sampling(indsd=_UMAP_,n=&tot_sampled_cells,nperm=1,dsdout=_UMAP_);
  %end;
  %else %do;
   %Sampling(indsd=_UMAP_,n=&down_sampling_num,nperm=1,dsdout=_UMAP_);
  %end;
%end;


******************add group means of x and y for labeling;
%if %length(&sample_grp_var)>0 %then %do;

proc sql;
create table _UMAP_ as
select a.*,
      %if "&xvar"^="x" %then 
       %str(&xvar as x,);
      %if "&yvar"^="y" %then 
      %str(&yvar as y,);
       median(&xvar)+std(&xvar) as x_,median(&yvar) as y_
from _UMAP_ as a
/* group by cluster, severity */
group by &cluster_var
order by &cluster_var, &sample_grp_var;
data _UMAP_;
set _UMAP_;
if not first.&cluster_var and not first.&sample_grp_var then do;
  x_=.;y_=.;
end;
by &cluster_var &sample_grp_var;
run;

%end;

%else %do;

proc sql;
create table _UMAP_ as
select a.*,
      %if "&xvar"^="x" %then 
       %str(&xvar as x,);
      %if "&yvar"^="y" %then 
      %str(&yvar as y,);
       median(&xvar)+std(&xvar) as x_,median(&yvar) as y_
from _UMAP_ as a
/* group by cluster, severity */
group by &cluster_var
order by &cluster_var;
data _UMAP_;
set _UMAP_;
if not first.&cluster_var then do;
  x_=.;y_=.;
end;
by &cluster_var;
run;

%end;


%if %length(&sample_grp_var)=0 %then %do;

ods graphics on/reset=all width=&fig_width height=&fig_height;
proc sgplot data=_UMAP_ noborder;
%if %length(&where_condition4cells)>0 %then %do;
where &where_condition4cells;
%end;

 *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of;
 *colors with 2nd datasymbols, and the same applied to other datasymbols;
/*  styleattrs datacontrastcolors=(green gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle) ; */
styleattrs 
datacontrastcolors=(
cxff0000 cxff4300 cxff8500
cxffc800 cxf4ff00 cx6fff00
cx2cff00 cx00ff16 cx00ff59
cx00ff9b cx00ffde cx00deff
cx009bff cx0059ff cx0016ff
cx2c00ff cx6f00ff cxb100ff
cxf400ff cxff00c8 cxff0085
cxff0043
) 
datasymbols=(
circlefilled starfilled triangle diamond square circle
);
*Reduce marker size will make the sc scatter plot prettier;
*but it is hard to link the symbol with its symbol legend;
scatter x=x y=y/group=&cluster_var markerattrs=(size=&marker_size) name='sc';
text x=x_ y=y_ text=&cluster_var/sizeresponse=y_ sizemin=&cell_label_size sizemax=&cell_label_size position=center;
label x="UMAP_1" y="UMAP_2";
*Need to use autoitemsize to increase the symbol size;
keylegend 'sc'/ autoitemsize;
%if %length(&rowaxis_min)>0 or %length(&rowaxis_max)>0 %then %do;
xaxis 
 %if %length(&rowaxis_min)>0 %then %str(min=&rowaxis_min); 
 %if %length(&rowaxis_max)>0 %then %str(max=&rowaxis_max);
 ;
%end;

%if %length(&colaxis_min)>0 or %length(&colaxis_max)>0 %then %do;
yaxis 
   %if %length(&colaxis_min)>0 %then %str(min=&colaxis_min);
   %if %length(&colaxis_max)>0 %then %str(max=&colaxis_max);
   ;
%end;
run;
%end;

%else %do;

%if %length(&ordered_sample_grps)>0 %then %do;
%rank4grps(
grps=&ordered_sample_grps,
dsdout=g
);

%mkfmt4grpsindsd(
targetdsd=_UMAP_,
grpvarintarget=&sample_grp_var,
name4newfmtvar=new_&sample_grp_var,
fmtdsd=g,
grpvarinfmtdsd=grps,
byvarinfmtdsd=num_grps,
finaloutdsd=umap_fmted
);

%end;

%else %do;

data umap_fmted;
set _UMAP_;
run;

%end;
/*
data umap_fmted;
set umap_fmted;
if prxmatch('/iliated/',&cluster_var) then do;
&cluster_var=lowcase(&cluster_var);
end;
run;
*/
/* proc print data=sub_map_fmted(obs=10);run; */

/* ods graphics on/width=1200 height=600; */
ods graphics on/width=&fig_width height=&fig_height ANTIALIASMAX=88200;
proc sgpanel data=umap_fmted;
/* where cluster not in ('Outlier' 'Outlier2') ; */
%if %length(&where_condition4cells)>0 %then %do;
where &where_condition4cells;
%end;
 *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of;
 *colors with 2nd datasymbols, and the same applied to other datasymbols;
/*  styleattrs datacontrastcolors=(green dardyellow gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle); */
styleattrs 
datacontrastcolors=(
cxff0000 cxff4300 cxff8500
cxffc800 cxf4ff00 cx6fff00
cx2cff00 cx00ff16 cx00ff59
cx00ff9b cx00ffde cx00deff
cx009bff cx0059ff cx0016ff
cx2c00ff cx6f00ff cxb100ff
cxf400ff cxff00c8 cxff0085
cxff0043
) 
datasymbols=(
circlefilled starfilled triangle diamond square circle
);
/* where cluster contains 'Ciliated'; */
%if %length(&ordered_sample_grps)>0 %then %do;
panelby new_&sample_grp_var/onepanel columns=&fig_column_num4sample_grps 
novarname skipemptycells uniscale=all;
%end;
%else %do;
panelby &sample_grp_var/onepanel columns=&fig_column_num4sample_grps 
novarname skipemptycells uniscale=all;
%end;
scatter x=x y=y/group=&cluster_var markerattrs=(size=&marker_size) name='sc';
text x=x_ y=y_ text=&cluster_var /sizeresponse=y_ sizemin=&cell_label_size sizemax=&cell_label_size;
label x="UMAP_1" y="UMAP_2";
keylegend 'sc'/ autoitemsize;
%if %length(&rowaxis_min)>0 or %length(&rowaxis_max)>0 %then %do;
rowaxis 
 %if %length(&rowaxis_min)>0 %then %str(min=&rowaxis_min); 
 %if %length(&rowaxis_max)>0 %then %str(max=&rowaxis_max);
 ;
%end;

%if %length(&colaxis_min)>0 or %length(&colaxis_max)>0 %then %do;
colaxis 
   %if %length(&colaxis_min)>0 %then %str(min=&colaxis_min);
   %if %length(&colaxis_max)>0 %then %str(max=&colaxis_max);
   ;
%end;
run;

/* ****************************Debugging***********************************; */
/* ods graphics on/width=1200 height=600; */
/* ods graphics on/width=1000 height=1600; */
/* proc sgpanel data=umap_fmted; */
/* where cluster not in ('Outlier' 'Outlier2') ; */
/* where cluster not in ('Outlier' 'Outlier2') and cluster contains 'iliated'; */
/*  *Only after using up the combination of all colors with the 1st datasymbol, it will use the combinations of; */
/*  *colors with 2nd datasymbols, and the same applied to other datasymbols; */
/*  styleattrs datacontrastcolors=(green dardyellow gold red black blue grey pink)   */
/*             datasymbols=(circlefilled starfilled triangle diamond square circle); */
/* styleattrs  */
/* datacontrastcolors=( */
/* cxff0000 cxff4300 cxff8500 */
/* cxffc800 cxf4ff00 cx6fff00 */
/* cx2cff00 cx00ff16 cx00ff59 */
/* cx00ff9b cx00ffde cx00deff */
/* cx009bff cx0059ff cx0016ff */
/* cx2c00ff cx6f00ff cxb100ff */
/* cxf400ff cxff00c8 cxff0085 */
/* cxff0043 */
/* )  */
/* datasymbols=( */
/* circlefilled starfilled triangle diamond square circle */
/* ); */
/* where cluster contains 'Ciliated'; */
/* panelby new_severity/onepanel columns=1 novarname; */
/* scatter x=x y=y/group=cluster markerattrs=(size=2) name='sc'; */
/* text x=x_ y=y_ text=cluster /sizeresponse=y_ sizemin=12 sizemax=12; */
/* label x="UMAP_1" y="UMAP_2"; */
/* keylegend 'sc'/ autoitemsize; */
/* rowaxis min=0 max=20000; */
/* colaxis min=40000 max=70000; */
/* run; */


%end;

%mend;

/*Demo code:;

%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname sc "%sysfunc(pathname(HOME))/data";

%debug_macro;

proc sql;
select unique(severity)
from sc.UMAP;

%sc_umap(
umap_ds=sc.umap,
xvar=x,
yvar=y,
cluster_var=cluster,
sample_grp_var=severity,
ordered_sample_grps=control_healthy severe critical,
down_sampling_num=0.5,
fig_width=1000,
fig_height=1400,
rowaxis_min=0,
rowaxis_max=,
colaxis_min=,
colaxis_max=,
where_condition4cells=%nrstr(), 
marker_size=2,
cell_label_size=12
);



*/

