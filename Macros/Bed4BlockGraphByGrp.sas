%macro Bed4BlockGraphByGrp(dsdin,mindist,maxdist,chr,chr_var,st_var,end_var,dsdout,graph_wd,graph_ht,show_block_values,Grp);
/*make sure no overlapping between each bed region*/
%local i block_values grp_list grp_n typic_colors color xi gi;

/*typical colors: lightgreen lightred lightblue lightgreen lightpink darkred*/
/*selected based Hex colors from SAS sgdesign*/
%let typic_colors=CXFFFFFF CXF6A48A CX98F19B CX7F91ED CXED85F2 CXE30735;

%if &show_block_values %then %let block_values=values;
%else %let block_values=;

proc sql;
select distinct &grp
into :grp_list separated by ' '
from &dsdin;
%let grp_n=%numargs(&grp_list);

%bed_block_complement4blockplot(dsdin=&dsdin,chr_var=&chr_var,chr_value=&chr,st_var=&st_var,end_var=&end_var,
dsdout=&dsdout,minst=&mindist,maxend=&maxdist,generate_dsd_only=0);

/*%abort 255;*/

%if &grp_n>1 %then %do;
/*Make a backup for the original dsd*/
data backup;
set &dsdout;
run;
%SingleDsd2MergedDsd4DiffGrps(singledsd=&dsdout,num_grp_var=grp,mergeddsd=&dsdout);
/*Merge the combined dsd with original dsd, as the original dsd will be used to make the background track*/
data &dsdout;
merge backup &dsdout;
run;
/*Need to reorder d4bar for each subgrp, otherwise, the blockplot will not generated correctly!*/
data &dsdout;
set &dsdout;
%do gi=1 %to &grp_n;
  grp&gi.d4bar=grp&gi.i;
%end;
run;
%end;

/*%abort 255;*/

/*Block graph*/
proc template;
define statgraph Graph;
dynamic _ST _N;
begingraph / designwidth=&graph_wd designheight=&graph_ht border=false;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      /*make sure to customize start and end, as well as viewmin and viewmax*/
      /*Make the fillattrs and altfillattrs have the same color, which will make the fixed axis for other subplots!*/
      /*datatransparency=1 will be better to make white background track*/
     %if &grp_n>1 %then %do;
      layout overlay / walldisplay=none xaxisopts=( display=(LINE TICKS TICKVALUES) linearopts=(viewmin=&mindist viewmax=&maxdist  tickvaluesequence=( start=%eval(&mindist-1) end=&maxdist increment=%eval((&maxdist-&mindist+1)/10) )));
         blockplot x=_ST block=_N / datatransparency=1 name='block' display=(FILL &block_values) filltype=alternate fillattrs=(color=CX0000FF) altfillattrs=(color=CX0000FF )
                                    valuehalign=center valuevalign=center;
          /*Add block values at the center of each block, which is not necessary when there are too many blocks to be visible!*/
         /*blockplot x=_ST block=_N / name='block' display=(FILL VALUES) filltype=alternate fillattrs=(color=CXFFFFFF) altfillattrs=(color=CX0000FF )
                                    valuehalign=center valuevalign=center;*/
		 /*Color different blocks by group*/
		%do xi=1 %to &grp_n;
          %let grp_i=%scan(&grp_list,&xi,%str( ));
		  %let color=%scan(&typic_colors,&xi,%str( ));
		  /*Make the altfillattrs with the fixed color CX0000FF as that is used by the 1st background track!*/
		  /*For different grps, change the fillattrs color accordingly*/ 
		  /*Note: here will use fixed var grp&grp_n.d4bar for each group*/
          blockplot x=grp&grp_i.pos block=grp&grp_i.d4bar / datatransparency=0.5 name="block&grp_i" display=(FILL &block_values) filltype=alternate fillattrs=(color=&color) altfillattrs=(color=CX0000FF)
                                    valuehalign=center valuevalign=center extendblockonmissing=true;
		%end;
	 %end;
	 %else %do;
      layout overlay / walldisplay=none xaxisopts=( display=(LINE TICKS TICKVALUES) linearopts=(viewmin=&mindist viewmax=&maxdist  tickvaluesequence=( start=%eval(&mindist-1) end=&maxdist increment=%eval((&maxdist-&mindist+1)/10) )));
         blockplot x=_ST block=_N / datatransparency=1 name='block' display=(FILL &block_values) filltype=alternate fillattrs=(color=CXFFFFFF) altfillattrs=(color=CX0000FF )
                                    valuehalign=center valuevalign=center;
	 %end;
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
dynamic _ST="pos" _N="i";
run;

ods printer close;
ods listing;

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

%Bed4BlockGraph(dsdin=bed
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
);

*/


/*Read Demo:

data bed;
input var1 $ var2 var3 var4 $;
cards;
chr7 50 400 BRCA_85940
chr7 500 800 BRCA_85941
chr7 850 900 BRCA_85958
chr7 950 1500 BRCA_86086
;
run;
*Check overlapped regions;
*This is already included into the macro Bed4BlockGraph, Demo here for recalling only;
%MergerOverlappedRegInBed(bedin=bed
                         ,chr_var=var1
                         ,st_var=var2
                         ,end_var=var3
                         ,bedout=xyz);

data xyz1;
set xyz;
if _n_<3 then grp=1;
else grp=2;
run;

options mprint mlogic symbolgen;

%Bed4BlockGraphByGrp(dsdin=xyz1
                ,mindist=1
                ,maxdist=2000
                ,chr=chr7
                ,chr_var=Var1
                ,st_var=Var2
                ,end_var=Var3
                ,dsdout=test
				,graph_wd=1200
				,graph_ht=100
                ,show_block_values=0
                ,grp=grp
);

*/

