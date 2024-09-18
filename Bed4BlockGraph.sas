%macro Bed4BlockGraph(
dsdin,
mindist,
maxdist,
chr,
chr_var,
st_var,
end_var,
dsdout,
graph_wd,
graph_ht,
show_block_values,
block_color=CX0000FF,	/*color for the bed block regions*/
gap_color=CXFFFFFF /*color for the space regions between bed regions*/
);
/*make sure no overlapping between each bed region*/

%if &show_block_values %then %let block_values=values;
%else %let block_values=;

data x0;
set &dsdin;
where &chr_var="&chr" and (
(&st_var between &mindist and &maxdist) or (&st_var<&mindist and &end_var>&mindist)
);
run;

/*Merged overlapped region in bed*/
%MergerOverlappedRegInBed(bedin=x0
                         ,chr_var=&chr_var
                         ,st_var=&st_var
                         ,end_var=&end_var
                         ,bedout=x);


data x;
set x;
bn=_n_;
if _n_=1 and &st_var>&mindist then tag=-1;
if _n_=1 and &st_var<=&mindist then do;
&st_var=&mindist;tag=1;
end;


proc sort data=x;by &st_var;run;
data x1;
set x;
array t{*} &st_var &end_var;
do i=0 to dim(t);
   if i=0 then do;
    st=&mindist;output;
   end;
   else if i=dim(t) and t{i}<&maxdist then do;
    st=t{i};output;st=&maxdist;tag=1;output;
   end;
   else if i=dim(t) and t{i}>=&maxdist then do;
    st=&maxdist+1;tag=-1;output;
   end;
   else do;
    st=t{i};
    output;
   end;
end;
drop i;
/*keep &chr_var st bn tag;*/
run;


/*assign even number as 0, which represent these blocks that are not of interest*/
proc sort data=x1 nodupkeys;by st;run;
data x2;
set x1;
n=_n_;
run;

data x2;
set x2;
d4bar=n;
if (bn=1 and tag=-1 and n=1) then n=0;
if (bn=1 and tag=1) then n=0;
dist=st-lag1(st);
run;


data x3;
retain grp4bar 0;
set x2;
if n^=0 then grp4bar=grp4bar+1;
if n^=0 and mod(grp4bar,2)=0 then do;
  x=1;
end;
run;

data &dsdout(drop=x);
length dsd $15.;
set x3 end=last;
if x=. then x=0;
grp4bar=x;
dsd="&dsdin";
cum_dist=st-&mindist;
if last and st=&maxdist and tag=1 then delete;/*important to keep the right block as excepted*/
if _n_=1 and tag=1 and st=&mindist then do;
st=&mindist+1;output;st=&mindist;output; /*important to keep the left block as excepted*/
end;
else do;
 output;
end;
run;

proc sort data=&dsdout;by st;run;
data &dsdout;
set &dsdout;
d4bar=_n_;
run;


/*Block graph*/
proc template;
define statgraph Graph;
dynamic _ST _N;
begingraph / designwidth=&graph_wd designheight=&graph_ht border=false;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      /*make sure to customize start and end, as well as viewmin and viewmax*/
			   /*Remove line from the display will lead to no xaxis line*/
      layout overlay / walldisplay=none xaxisopts=(display=(TICKS TICKVALUES) linearopts=(viewmin=&mindist viewmax=&maxdist  tickvaluesequence=( start=%eval(&mindist-1) end=&maxdist increment=%eval((&maxdist-&mindist+1)/10) )));
         blockplot x=_ST block=_N / name='block' display=(FILL &block_values) filltype=alternate fillattrs=(color=&gap_color) altfillattrs=(color=&block_color )
                                    valuehalign=center valuevalign=center;
          /*Add block values at the center of each block, which is not necessary when there are too many blocks to be visible!*/
         /*blockplot x=_ST block=_N / name='block' display=(FILL VALUES) filltype=alternate fillattrs=(color=CXFFFFFF) altfillattrs=(color=CX0000FF )
                                    valuehalign=center valuevalign=center;*/
      endlayout;
   endlayout;
endgraph;
end;
run;

/*change display=(FILL VALUES) if want to remove values in blocks or filltype=multicolor as filltype=alternate*/
/*change display=(FILL VALUES) as display=(FILL)*/

options printerpath=svg;
ods listing close;
ods printer file="&dsdin..svg";

title "Block graph for dsd: &dsdin";
proc sgrender data=&dsdout template=Graph;
dynamic _ST="ST" _N="d4bar";
run;
title;
ods printer close;
ods listing;


/*Bar graph*/
/*proc template;*/
/*define statgraph sgdesign;*/
/*dynamic _DIST _D4BAR _V1A;*/
/*begingraph / designwidth=1006 designheight=134;*/
/*   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;*/
/*      layout overlay / walldisplay=none xaxisopts=( display=(LINE )) yaxisopts=( display=(LINE ) discreteopts=( tickvaluefitpolicy=none));*/
/*         barchart category=_V1A response=_DIST / group=_D4BAR name='bar(h)' display=(FILL) stat=mean orient=horizontal barwidth=0.85 groupdisplay=Stack clusterwidth=1.0 grouporder=ascending;*/
/*      endlayout;*/
/*   endlayout;*/
/*endgraph;*/
/*end;*/
/*run;*/
/**/
/*proc sgrender data=&dsdout template=sgdesign;*/
/*dynamic _DIST="DIST" _D4BAR="D4BAR" _V1A="Var1";*/
/*run;*/
/**/

%mend;
/*
proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\BRCA.Enhancer.bed"
dbms=tab out=BRCA replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\PRAD.Enhancer.bed"
dbms=tab out=PRAD replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\LUAD.Enhancer.bed"
dbms=tab out=LUAD replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\STAD.Enhancer.bed"
dbms=tab out=STAD replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\LGG.Enhancer.bed"
dbms=tab out=LGG replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\BLCA.Enhancer.bed"
dbms=tab out=BLCA replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\CESC.Enhancer.bed"
dbms=tab out=CESC replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\HNSC.Enhancer.bed"
dbms=tab out=HNSC replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\SKCM.Enhancer.bed"
dbms=tab out=SKCM replace;
getnames=no;guessingrows=10000;
run;

proc import datafile="E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\Enhancers\COAD.Enhancer.bed"
dbms=tab out=COAD replace;
getnames=no;guessingrows=10000;


*/

/*EGFR +/-10kb: chr7:55076971-55266642*/

/*

%Bed4BlockGraph(dsdin=BRCA
                ,mindist=55076971
                ,maxdist=55266642
                ,chr=chr7
                ,chr_var=Var1
                ,st_var=Var2
                ,end_var=Var3
                ,dsdout=out_BRCA
				,graph_wd=1000
				,graph_ht=60
                ,show_block_values=0
);


E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\BedBarplot.sgd
E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\BedBlockplot.sgd




data a;
input r $;
cards;
BRCA
PRAD
HNSC
LUAD
LGG
STAD
CESC
SKCM
COAD
BLCA
;


options mprint mlogic symbolgen;

*NT: use nrstr to mask macrofullcommand and not run macro variable within the macrofullcommand;
*&RepeatVar is a macro var to represent one of macro vars based on the Mvar_dsd and Mvar;
*&RepeatVar will be used repeatly to represent each macro var in the Demo macro or other macro;
*MacroFullCommand need to customized for different macro by assigning &RepeatVar to specific macro var;

%RunMacrosRepeatedly(Mvar_dsd=a,
                     Mvar=r,
                     MacroFullCommand=%nrstr(%%Bed4BlockGraph(dsdin=&RepeatVar,mindist=55240546,maxdist=55250546,chr=chr7,chr_var=Var1,st_var=Var2,end_var=Var3,dsdout=out_&RepeatVar,graph_wd=1000,graph_ht=60,show_block_values=1)));

data ALL;
set out_:;
run;

E:\Temp\TCGA_Paper_Scripts\To-do-list\ScienceNewEnhancer4ASE_Mut_Assoc\BedBlockplot4MultipleDsd.sgd

*/


/*
When create graphs with sgdesiner, make sure to fix the x-axis start and end value as &mindist-1 and &macdist;
Otherwise the block plots would be wrong;

*/


/*Simple Demo for debug
data bed;
input var1 $ var2 var3;
cards;
chr7 10 30
chr7 40 70
chr7 80 400
chr7  410 1500
run;

%Bed4BlockGraph(
dsdin=bed
,mindist=10
,maxdist=1400
,chr=chr7
,chr_var=Var1
,st_var=Var2
,end_var=Var3
,dsdout=test
,graph_wd=1000
,graph_ht=60
,show_block_values=0
,block_color=darkred
,gap_color=white
);

*/


/*Read Demo:

data bed;
input var1 $ var2 var3 var4 $;
cards;
chr7	55081541	55082042	BRCA_85940
chr7	55082274	55082775	BRCA_85941
chr7	55090588	55091089	BRCA_85950
chr7	55094020	55094521	BRCA_85951
chr7	55094755	55095256	BRCA_85952
chr7	55097912	55098413	BRCA_85953
chr7	55100869	55101370	BRCA_85954
chr7	55101993	55102494	BRCA_85955
chr7	55103050	55103551	BRCA_85956
chr7	55111369	55111870	BRCA_85957
chr7	55111929	55112430	BRCA_85958
chr7	55269774	55270275	BRCA_86086
chr7	55270628	55271129	BRCA_86087
chr7	55271686	55272187	BRCA_86088
chr7	55272829	55273330	BRCA_86089
chr7	55275131	55275632	BRCA_86090
chr7	55276051	55276552	BRCA_86091
chr7	55279749	55280250	BRCA_86092
chr7	55280467	55280968	BRCA_86093
;
run;
*Check overlapped regions;
*This is already included into the macro Bed4BlockGraph, Demo here for recalling only;
%MergerOverlappedRegInBed(bedin=bed
 ,chr_var=var1
,st_var=var2
,end_var=var3
,bedout=xyz);

%Bed4BlockGraph(
dsdin=xyz
,mindist=55076725
,maxdist=55097925
,chr=chr7
,chr_var=Var1
,st_var=Var2
,end_var=Var3
,dsdout=test
,graph_wd=1000
,graph_ht=160
,show_block_values=0
,block_color=darkred
,gap_color=white
);

data xyz1;
set xyz;
if _n_<5 then grp=1;
else grp=2;
run;

%Bed4BlockGraph(
dsdin=xyz1
,mindist=55076725
,maxdist=55285031
,chr=chr7
,chr_var=Var1
,st_var=Var2
,end_var=Var3
,dsdout=test
,graph_wd=1000
,graph_ht=160
,show_block_values=0
,block_color=darkred
,gap_color=white
);

*/

