*Note: this macros is the old version as it only can handle single GWAS;
*For better performance, it is suggest to use the following macro, which can plot multiple GWASs;
*Manhattan4DiffGWASs.sas;

* macro that can be used later to generate symbols for plots with two alternating colors;
%macro twocolors(c1,c2);
%do j=1 %to 23 %by 2;
symbol&j v=dot c=&c1;
symbol%eval(&j+1) v=dot c=&c2;
%end;
%mend;

%macro uniqcolors;
/*https://support.sas.com/content/dam/SAS/support/en/books/pro-template-made-easy-a-guide-for-sas-users/62007_Appendix.pdf*/
*For standard RGB chars generated by inkscape, it is necessary to remove the last two chars ff and put cx at the beginning;
symbol1 v=dot h=&dotsize c=cx0072bd;
symbol2 v=dot h=&dotsize c=cxd95319;
symbol3 v=dot h=&dotsize c=cxedb120;
symbol4 v=dot h=&dotsize c=cx7e2f8e;
symbol5 v=dot h=&dotsize c=cx77ac30;
symbol6 v=dot h=&dotsize c=cx4dbeee;
symbol7 v=dot h=&dotsize c=cxa2142f;
symbol8 v=dot h=&dotsize c=cx0072bd;
symbol9 v=dot h=&dotsize c=cxd95319;
symbol10 v=dot h=&dotsize c=cxedb120;
symbol11 v=dot h=&dotsize c=cx7e2f8e;
symbol12 v=dot h=&dotsize c=cx77ac30;
symbol13 v=dot h=&dotsize c=cx4dbeee;
symbol14 v=dot h=&dotsize c=cxa2142f;
symbol15 v=dot h=&dotsize c=cx0072bd;
symbol16 v=dot h=&dotsize c=cxd95319;
symbol17 v=dot h=&dotsize c=cxedb120;
symbol18 v=dot h=&dotsize c=cx7e2f8e;
symbol19 v=dot h=&dotsize c=cx77ac30;
symbol20 v=dot h=&dotsize c=cx4dbeee;
symbol21 v=dot h=&dotsize c=cxa2142f;
symbol22 v=dot h=&dotsize c=cx0072bd;
symbol23 v=dot h=&dotsize c=cxd95319;
%mend;


%global chr_var;*Make sure we can asign new vale to it in some IF condition;
*This will be used by color macros for different chromosomes;
%global dotsize;

*Make sure the dsdin is with numeric chr and sorted by numeric chr and pos!;
%macro manhattan(dsdin=,pos_var=,chr_var=,P_var=,logP=,gwas_thrsd=,
dotsize=4,gwas_sortedby_numchrpos=0,
use_uniq_colors=1 /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
);

/**fake data;*/
/*data manhattan ;*/
/*Fake_position=1; */
/*do &chr_var=1 to 22;*/
/*do _n_=1 to ( 1e6 - &chr_var * 10000 ) - 1 by 1000 ;*/
/*   Fake_position + _n_ / 1e6 ;*/
/*   logp = -log( ranuni(2)) ;*/
/*   output ;*/
/*end;*/
/*end;*/
/*run;*/


*Check &chr_var type for preparing of making alternative var _chr_ for plotting;
*Note: will create a global var: var_type, which can be used in other macro;
%check_var_type(
dsdin=&dsdin,
var_rgx=&chr_var
);
%put Created a global var for chr, its type of which is &var_type;
/*%put the macro chr_var is &chr_var;*/

*For char &chr_var;
%if "&var_type"="2" %then %do;
/*This step will take a lot of disk space*/
data &dsdin;
set &dsdin;
frq=1;
run;
/*use the frq for sorting by total number of data points*/
%format_xaxis_with_numeric_order(
dsdin=&dsdin,
Xaxis_vars=&chr_var,
new_Xaxis_var=_chr_,
Var4sorting_Xaxis=frq,
function4sorting=count,
descending_or_not=0,
dsdout=&dsdin,
createdfmtname=Xaxis_var_label);

/*Use the following when the above failed*/
/* This will change char chr labels into numeric ones */
/* Used when it is necessary */

/* %chr_format_exchanger( */
/* dsdin=&dsdin, */
/* char2num=1, */
/* chr_var=&chr_var, */
/* dsdout=&dsdin); */

*Just try to reuse the above function, the function4sorint is not useful;
*so asign missing value for it;
%let chr_var=_chr_;
%end;


*real data;
%if %eval("&gwas_thrsd"="") %then %do;
%let gwas_thrsd=7.3;
%end;

%if &gwas_sortedby_numchrpos=0 %then %do;
proc sort data=&dsdin;
by &chr_var &pos_var;
run;
%end;

%let nrows=%rows_in_sas_dsd(test_dsd=&dsdin);
%put There are &nrows in your dataset;

/*For EWAS;*/
%if (&nrows lt 100000 and &nrows gt 30000) %then %do;
data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ / 1e2 ;/*This part will affect the Xaxis dramaticall*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;
/*For local EWAS or GWAS;*/
%else %if (&nrows lt 30000 and &nrows gt 4000) %then %do;

data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ /2 ;/*This part will affect the Xaxis dramaticall*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;
/*For local EWAS or GWAS;*/
%else %if &nrows le 4000 %then %do;
data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ ;/*This part will affect the Xaxis dramaticall*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;
/*For GWAS*/
%else %do;
data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ / 1e3 ;/*This part will affect the Xaxis dramaticall*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;


data manhattan(keep=logp Fake_position &chr_var);
set manhattan(where=(&P_var^=.));
%if (&logP=1) %then %do;
logp=-log10(&P_var);
%end;
%else %do;
logp=&P_var;
%end;
run;

%if &gwas_sortedby_numchrpos=0 %then %do;
proc sort data=manhattan;
by &chr_var Fake_position;
run;
%end;

 
*find maximum value for the x-axis, store in a macro variable;
proc sql noprint;
select 1.005*ceil(max(Fake_position)) into :maxbp 
from manhattan;
quit;
 
* 
find mean of BP within each chromosome (C)
used later to position x-axis labels
;
proc summary data=manhattan nway;
class &chr_var;
var Fake_position;
output out=mbp mean=;
run;

 
* 
annotate data set used to add x-axis labels
"manually" add the frame around the graph
possibly add a horizontal reference line
;
data anno ;
retain position '8' xsys ysys '2' y 0 function 'label' text 'xx';
do until (last1);
   set mbp (keep = Fake_position &chr_var) end=last1;;
   x = round(Fake_position) ;
   text = cat(&chr_var);
   if text="20" or text="22"  then text=" ";   
   output;
end;
 
* top of frame;
xsys = '1'; ysys = '1'; function = 'move'; x = 0; y=100; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
* bottom of frame;
xsys = '1'; ysys = '1'; function = 'move'; x = 0; y=0; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
 
* horizontal reference line (if needed for 5x10-08);
xsys = '1'; ysys = '2'; function = 'move'; x = 0; y=&gwas_thrsd; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
run;
 
* reset all then set some graphics options;
%let fontsize=4;
*If put reset=all inside the command of goptions, the title will be removed;
*It is necessary to reset all here, otherwise, the figure may be distorted;
goptions reset=all ftext='arial' htext=&fontsize gunit=pct 
         dev=gif xpixels=1400 ypixels=400 gsfname=gout;
 
* make some room around the plot (white space);
title1 ls=2;
title2 a=90 ls=2;
title3 a=-90 ls=2;
footnote1 ls=2;
 
* let SAS choose the colors;
* use h=5 to set dot size for the plot;
/* symbol1 v=dot r=22 h=&dotsize; */

* let SAS choose the colors;
* use h=5 to set dot size for the plot;
%if &use_uniq_colors=0 %then %do;
symbol1 v=dot r=22 h=&dotsize;
%end;
%else %do;
%uniqcolors; 
%end;
 
* two alternating colors;
* gray-scale;
*%twocolors(gray33,graycc);
* blue and blue-green;
*%twocolors(cx2C7FB8,cx7FCDBB);
 
* suppress drawing of any x-axis feature;
axis1 value=none major=none minor=none label=none style=0;
* rotate y-axis label;
axis2 label=(angle=90 "-Log10(p)" f='arial' h=&fontsize) 
      value=(f='arial' h=&fontsize);
 
* destination for the plot;
filename gout './manhattan1.gif';
 
* use PROC GPLOT to create the plot;
*Add format for customized &chr_var labels;
*Make sure to remove nolegend;
%if "&var_type"="2" %then %do;
/*Note: the offset setting will make the legend move left when value is negative!*/
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/graphref/p0anvu6ux4d0ijn1mt06fn9yl0wx.htm#p18f31f18e6elan1ge5bb2pjiv34;
legend1 across=6 down=3 repeat=1 label=(height=4 position=top justify=center 'Marker')
        value=(height=3) shape=symbol(3,3) offset=(0,0)cm
        position=(top center outside);
proc gplot data=manhattan ;
plot logp*Fake_position=&chr_var / haxis = axis1
                 vaxis = axis2
                 href  = &maxbp
                 annotate = anno
               /*nolegend*/
		         noframe
		         legend=legend1
;
format &chr_var Xaxis_var_label.;
label Fake_position="Groups"
      &chr_var="Legends of groups";
run;
%end;

%else %do;
proc gplot data=manhattan ;
plot logp*Fake_position=&chr_var / haxis = axis1
                 vaxis = axis2
                 href  = &maxbp
                 annotate = anno
                 nolegend
		         noframe
;
run;
%end;

%mend;

/*

%Import_Space_Separated_File(abs_filename=E:\Yale_GWAS\ALL_GWGO_HCE_EA_combined_meta.txt,
                             firstobs=1,
							 getnames=yes,
                             outdsd=Assoc);


%manhattan(dsdin=sasuser.Assoc,
           pos_var=Pos,
           chr_var=Chr,
           P_var=P,
           logP=1);
*/




/*
<placed after first data step>
* add some fake info to the data set (SNP name and a p-value);
data manhattan;
set manhattan;
snp_name = cats('rs',_n_);
if ranuni(0) lt .0005 then p_value = 10e-6;
else p_value = 0.1;
run;
 
<modified data step to create the annotate data set>
* 
annotate data set used to add x-axis labels
"manually" add the frame around the graph
possibly add a horizontal reference line
add labels to selected points;
;
data anno ;
length color $8 text $25;
retain position '8' xsys ysys '2' y 0 function 'label' when 'a';
do until (last1);
   set mbp (keep = bp c) end=last1;;
   x = round(bp) ;
   text = cat(c);
   output;
end;
 
* top of frame;
xsys = '1'; ysys = '1'; function = 'move'; x = 0; y=100; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
* bottom of frame;
xsys = '1'; ysys = '1'; function = 'move'; x = 0; y=0; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
 
* horizontal reference line (if needed);
xsys = '1'; ysys = '2'; function = 'move'; x = 0; y=4; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
 
* this portion adds labels for points with p_value le 10e-6;
function = 'label';
hsys = '3';
size = 1.5;
position = '5';
cbox = 'white';
color = 'blue';
do until (last2);
   set manhattan end=last2;
   where p_value le 10e-6;
   x = bp;
   y = logp;
   text = snp_name;
   output;
end;
 
run;
*/
