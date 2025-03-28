%macro boxplotbygrp(
dsdin=,
grpvar=,
category_var=%nrstr(&grpvar),
valvar=,
panelvars=,
attrmap_dsd=,
fig_height=600,
fig_width=600,
transparency=0.3,
boxwidth=0.5,
column_num=4
);
/*proc import datafile="/home/cheng.zhong.shan/data/out.txt" dbms=tab out=x replace;getnames=yes;run;*/

/* proc print data=x(obs=10);run; */

/* data _null_; */
/* rc=dlgcdir("/home/cheng.zhong.shan/data"); */
/* put rc=; */
/* run; */
/*  */
/* proc template; */
/* define statgraph boxplotgroup; */
/* begingraph/datacolors=(lightpink lightblue lightred); */
/*  */
/* layout overlay/Yaxisopts=(offsetmin=0.1 offsetmax=0.1 reverse=false); */
/* boxplot x=cohort y=exp/orient=vertical group=grp groupdisplay=cluster name="level"; */
/* discretelegend "level"; */
/* endlayout; */
/*  */
/* endgraph; */
/* end; */
/* run; */
/*  */
/* options printerpath=svg; */
/* ods listing close; */
/* ods printer file="boxplot.svg"; */
/* proc sgrender data=x template=boxplotgroup; */
/* run; */
/* ods listing close; */
/* ods listing; */

/* This is a better scrip; */

*can not include data step cards in macro;

/*
data attrmap;
retain id "myid" linecolor "black";
length value $ 5 fillcolor $ 15;
input value $ fillcolor $;
cards;
High lightred
Low lightblue
;
run;
*/

/*
data _null_;
rc=dlgcdir("/home/cheng.zhong.shan/data");
put rc=;
run;
*/
data &dsdin;
set &dsdin;
*add the var for making colaxistable;
n=1;
run;

options printerpath=svg;
/* ods listing close; */
/* ods printer file="boxplot_by_sgpanel.svg"; */
/* %if &fig_height>2000 %then %do; */
/* %let fig_height=2000; */
/* *Let SAS to design the appropriate figure width; */
/* ods graphics /reset=all height=&fig_height noborder; */
/* %end; */
/* %else %do; */
ods graphics /reset=all height=&fig_height width=&fig_width noborder;
/* %end; */

%if %length(&attrmap_dsd)>0 %then %do;
 proc sgpanel data=&dsdin noautolegend dattrmap=&attrmap_dsd;
%end;
%else %do;
proc sgpanel data=&dsdin noautolegend;
%end;
panelby &panelvars /novarname onepanel columns=&column_num skipemptycells proportional;
/* panelby &panelvars /rows=1 novarname onepanel; */
vbox &valvar/group=&grpvar category=%unquote(&category_var) groupdisplay=cluster attrid=myid grouporder=ascending
         outlierattrs=(color=black symbol=circlefilled size=3)
         whiskerattrs=(color=black thickness=2 pattern=3) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=black symbol=circlefilled color=black size=8) 
         transparency=&transparency boxwidth=&boxwidth;
*It is important to add category=popsex for the colaxistable;
*otherwise, the following code will fail;
colaxistable n/stat=sum position=bottom class=&grpvar classdisplay=cluster; 
         
run;
/* ods listing close; */
/* ods listing; */


*Other good boxplot setting for modification;
/* ods graphics on/ reset=all width=500 height=800 noborder; */
/* proc sgpanel data=exp; */
/* where prxmatch("/(Apobec3|gapdh)/i",genesymbol); */
/* panelby grp/columns=2 onepanel novarname uniscale=column  */
/* headerattrs=(size=8 family=arial style=normal) sort=ASCMEAN ; */
/* vbox exp/group=popsex groupdisplay=cluster category=popsex boxwidth=0.6 fillattrs=(transparency=0.5)  */
/* whiskerattrs=(pattern=2 thickness=2) */
/* meanattrs=(symbol=circlefilled color=darkgreen size=5); */
/* vbox exp/group=pop %boxgrpdisplaysetting; */
/* *It is important to add category=popsex for the colaxistable; */
/* *otherwise, the following code will fail; */
/* colaxistable n/stat=sum position=bottom class=pop classdisplay=cluster;  */
/* run; */

%mend;

/*Demo:
*Need to have the following attrmap dsd and ensure to include the same variables;
data attrmap;
retain id "myid" linecolor "black";
length value $ 5 fillcolor $ 15;
input value $ fillcolor $;
cards;
High lightred
Low lightblue
;
run;

%boxplotbygrp(dsdin,grpvar,valvar,panelvars,attrmap_dsd);

*/


