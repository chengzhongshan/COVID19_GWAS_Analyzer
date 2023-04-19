%macro boxplotbygrp(dsdin,grpvar,valvar,panelvars,attrmap_dsd);
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

options printerpath=svg;
ods listing close;
ods printer file="boxplot_by_sgpanel.svg";
proc sgpanel data=&dsdin dattrmap=&attrmap_dsd;
panelby &panelvars /novarname onepanel;
/* panelby &panelvars /rows=1 novarname onepanel; */
vbox &valvar/group=&grpvar groupdisplay=cluster attrid=myid grouporder=ascending
         outlierattrs=(color=black symbol=circlefilled size=5)
         whiskerattrs=(color=black thickness=2 pattern=3) 
         medianattrs=(color=black thickness=2 pattern=1) 
         meanattrs=(color=black symbol=circlefilled color=black size=8);
run;
ods listing close;
ods listing;

quit;



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


