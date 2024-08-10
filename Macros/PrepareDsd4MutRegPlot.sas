%macro PrepareDsd4MutRegPlot(
dsd,
pos_var,
ID_var4yaxis,
x_st4mut,
x_end4mut,
gr4color,
pic_wd,
pic_ht,
dot_size,
dsdout,
seriesplot=0,
yoffsetmin=0.01, /*Adjust the y-axis offset min or max to prevent the axis overlap with barplot*/
yoffsetmax=0.01,
xoffsetmin=0.01,
xoffsetmax=0.01,
colors4grps=CXd17800 CX47a82a CXb38ef3 CXf9da04  CX445694 CXdd988f CX01665e CX8da7cd CX9d3cdb CX7f8e1f CX2597fa CXb26084 
/*Assign custom colors for bar groups from upper to bottom bars;*/
);

*Asign missing values for these rows if its positions are out of the query range;
data &dsd.tmp;
set &dsd;
if (&pos_var < &x_st4mut or &pos_var > &x_end4mut) then &pos_var=.;
run;

proc sort data=&dsd.tmp out=tmp nodupkeys;by &gr4color &pos_var;
data tmp;
set tmp;
ord=_n_;

proc sql;
create table &dsdout as
select a.*,b.ord
from &dsd.tmp as a
left join
tmp as b
on a.&gr4color=b.&gr4color and
   a.&ID_var4yaxis=b.&ID_var4yaxis;

data &dsdout;
set &dsdout;
value=&pos_var-&x_st4mut;
g=&gr4color;
I=ord;
_value_=&x_end4mut-&x_st4mut;
*Also consider these samples containing missing data;
*This will draw a plot for all samples;
where (&pos_var between &x_st4mut and &x_end4mut) or &pos_var=.;
run;

proc sort data=&dsdout nodupkeys;by &ID_var4yaxis &gr4color value;run;
*Important here;
*This is updated later, due to the above sorting procesure does not work;
*Draw these dots according to their group membership and postion value;
proc sort;by g value;run;
data &dsdout;
set &dsdout;
I=_n_;
ord=_n_;
run;

*Add (0,I) data points for making horizatonal reference lines;
data &dsdout;
set &dsdout;
v0=0;
output;
ref_tag=1;
v0=_value_;
output;
run;
*Except for variable I, make all other numeric variable as missing when ref_tag=1;
data &dsdout;
set &dsdout;
if ref_tag=1 then do;
	_value_=.;value=.;ord=.;pos=.;
end;
run;

/*define color for block data*/

/*define template for mutation regional plot*/
proc template;
define statgraph Graph;
dynamic _I _G _VALUE2 _I2 __VALUE_ _V0A _I3 _I4;
begingraph / designwidth=&pic_wd designheight=&pic_ht;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      *Note: yaxis is reversed!;
       *Note: offsetmax=0 or offsexmin=0 for each axis will remove the blank spaces close to each axis;
        *It is necessary to adjust y-axis offsetmin and offsetmax to prevent the upper and lower bars cut by the axis;
      layout overlay / walldisplay=none xaxisopts=( offsetmin=&xoffsetmin offsemax=&xoffsetmax display=(TICKS TICKVALUES LINE)) 
                                yaxisopts=(offsetmin=&yoffsetmin offsemax=&yoffsetmax reverse=true type=discrete display=none discreteopts=( tickvaluefitpolicy=none));
	     	*It is important to give full width for bar when the display of bar is filled by specific color;
        barchart category=_I response=__VALUE_ / group=_G name='bar_h' display=(FILL) stat=mean orient=horizontal barwidth=1.0 discreteoffset=0.02 groupdisplay=Stack clusterwidth=1.0;
         scatterplot x=_VALUE2 y=_I2 / name='scatter' markerattrs=(color=black symbol=CIRCLEFILLED size=&dot_size );
		  %if %eval(&seriesplot=1) %then %do;
		   seriesplot x=_V0A y=_I3 / group=_I4 name='series' connectorder=xaxis datatransparency=0.5 lineattrs=(color=CX000000 pattern=thindot);
		  %end;
      endlayout;
   endlayout;
endgraph;
end;
run;

/*default is listing style;*/
%Barchart_color_template(colors=&colors4grps,
                         temp_out=blockstyle);

ODS listing style=blockstyle image_dpi=300;

/*Doesn't work*/
/*
options printerpath=svg;
ods listing close;
ods printer style=blockstyle;
*/
ods listing close;
ods html style=blockstyle image_dpi=300 file="myblock.html";
ods graphics/border=off;

proc sgrender data=&dsdout template=Graph;
dynamic _I="I" _G="G" _VALUE2="VALUE" _I2="I" __VALUE_="'_VALUE_'n" _V0A="V0" _I3="I" _I4="I";
run;

/*ods printer close;*/
ods listing;

%mend;

/*E:\Temp\TCGA_Paper_Scripts\To-do-list\Mutation locuszoom plot.sgd*/


/*%ImportFilebyScanAtSpecCols(file=F:\NewTCGAAssocRst\BRCA\MatlabAnalysis\BRCA_AllTestedMutASE4Matlab.txt*/
/*                 ,dsdout=dsd*/
/*                 ,firstobs=1*/
/*                 ,dlm='09'x*/
/*                 ,ImportAllinChar=1*/
/*                 ,MissingSymb=NaN*/
/*				 ,SpeColNums=2 5*/
/*);*/

/*

%RecSearchFiles2dsd(
root_path=F:\NewTCGAAssocRst,
filter=_AllTestedMutASE4Matlab.txt$,                                   
perlfuncpath=F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes,
outdsd=filenames,
outputfullfilepath=1);

%ImportFilesInDSDbyScan(
filedsd=filenames
,filename_var=filefullname
,filedir=
,fileRegexp=_AllTestedMutASE
,dsdout=dsd
,firstobs=1
,dlm='09'x
,ImportAllinChar=1
,MissingSymb=NaN
,notverbose=1
,debug=0
);

data dsd;
length chr $5.;
set dsd;
where mut^="NaN";
chr=scan(mut,1,':');
pos=scan(mut,2,':')+0;
run;

data a;
set dsd;
where chr='chr9';
run;

data a;
length type $4.;
set a;
type=scan(memname,3,'/');
run;


data all;
set a;
do cancer=1 to 12;
pos=pos-100*cancer;output;
end;
run;


%PrepareDsd4MutRegPlot(dsd=a,
 pos_var=pos,
 ID_var4yaxis=ID,
 x_st4mut=139386896,
 x_end4mut=139442238,
 gr4color=type,
 pic_wd=150,
 pic_ht=200,
 dot_size=2,
 dsdout=ab_New,
yoffsetmin=0.05,
yoffsetmax=0.05,
xoffsetmin=0.01,
xoffsetmax=0.01,
colors4grps=lightred lightgreen lightblue red green blue darkred darkgreen darkblue
);
proc sort data=ab_New out=ab_uniq nodupkeys;by type mut ID;run;
proc freq data=ab_uniq;
table type;
run;

proc import datafile="F:\NewTCGAAssocRst\Bed_Tracks\All_Roadmap_H3K27ac_Union_Enhancer_Sum10.bed" dbms=tab out=track replace;
getnames=no;guessingrows=10000;
run;

data t;
set track;
where var1="chr9" and 
   (var2 between 139386896 and 139442238);
run;



*Updated on Jan-20-2020;
*Make the macro to draw a plot for ALL samples, including these samples with missing data;

data z;
length ID $12.;
input type $	chr $	ID $	pos;
cards;
BLCA	chr6	TCGA-BT-A0S7	160381329
BLCA	chr6	TCGA-G2-A2ES	160395213
BLCA	chr6	TCGA-BT-A3PH	160398232
BLCA	chr6	TCGA-C4-A0F7	160404506
BLCA	chr6	TCGA-C4-A0F7	160404507
BLCA	chr6	TCGA-BT-A0YX	160452629
BLCA	chr6	TCGA-DK-A1AC	160462881
BLCA	chr6	TCGA-DK-A1AC	43738316
BLCX	chr6	TCGA-DK-A1Ax	1
BLCX	chr6	TCGA-DK-A1Ay	2
;
run;

*options mprint mlogic symbolgen;
%PrepareDsd4MutRegPlot(dsd=z,
 pos_var=pos,
 ID_var4yaxis=ID,
 x_st4mut=160381329,
 x_end4mut=160404508,
 gr4color=type,
 pic_wd=800,
 pic_ht=800,
 dot_size=5,
 dsdout=z_new,
 seriesplot=0,
yoffsetmin=0.05,
yoffsetmax=0.05,
xoffsetmin=0.01,
xoffsetmax=0.01,
colors4grps=lightred lightgreen lightblue
);

*Optimize the template by using the sgd graph template: ;
*F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\SAS_Code_Database\mutation heatmap sgd graph template.sgd;

*/



											 
