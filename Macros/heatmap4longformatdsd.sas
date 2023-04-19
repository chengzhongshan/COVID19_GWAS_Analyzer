%macro heatmap4longformatdsd(
dsdin,
xvar,
yvar,
colorvar,
fig_height,
fig_width,
outline_thickness=0,/*Provide number > 0 to add white outline to separate each cell in heatmap*/
user_yvarfmt=,	/*default is to not use format*/
user_xvarfmt=, /*default is to not use format*/
colorbar_position=right,/*left, right, top, or bottom for gradlegend*/
colorrange=blue green red, /*color range used for heatmap*/
yfont_style=normal, /*normal or italic for yaxis font type*/
xfont_style=Italic, /*normal or italic for xaxis font type*/
NotDrawYaxisLabels=0, /*Remove Yaxis labels when there are too many groups for y axis*/
NotDrawXaxisLabels=0	 /*Remove Xaxis labels when there are too many groups for x axis*/
);


%getdsdvarsfmt(dsdin=&dsdin,fmtdsdout=fmtinfo);
proc sql noprint;
select catx('',format,'.') into: xvar_fmt
from fmtinfo 
where upcase(name)=upcase("&xvar");
select catx('',format,'.') into: yvar_fmt
from fmtinfo 
where upcase(name)=upcase("&yvar");


ods graphics / reset=all width=&fig_width.px height=&fig_height.px noborder;
/* proc sgplot data=x(where=(cohort="Laval")); */
*Remove border with 'noborder';
proc sgplot data=&dsdin noborder;

*Make sure to format the vars within proc sgplot here;
*Can not use formats within axis commands;
 %if %eval(&xvar_fmt^=.) %then %do;
  format &xvar &xvar_fmt;
 %end;
 %else %if (&user_xvarfmt ne ) %then %do;
  format &xvar &user_xvarfmt; 
 %end;
 
 %if %eval(&yvar_fmt^=.) %then %do;
  format &yvar &yvar_fmt;
 %end;
 %else %if (&user_yvarfmt ne ) %then %do;
  format &yvar &user_yvarfmt; 
 %end; 
 
/*outline and its attrs are important for making white grid*/
%if &colorvar ne  %then %do;
        heatmapparm x=&xvar y=&yvar colorresponse=&colorvar
%end;
%else %do;
/*if no colorvar supplied, the macro will draw a freq heatmap*/
  %if &xvar ne and &yvar ne %then %do;
        heatmap x=&xvar y=&yvar
   %end;
   %else %do;
        %put You need to provide at least one of xvar and yvar;
        %abort 255;
   %end;
%end;
            /
												%if &outline_thickness > 0 %then %do;
												%*Only when outline_thinkness >0 we will add outline;
												 outline
             outlineattrs=(color=white thickness=&outline_thickness pattern=solid)
												%end;
             colormodel=(&colorrange)
            ;
/*customize gene font and font size*/ 
xaxis 
%if &NotDrawXaxisLabels=1 %then %do;
  display=(novalues noticks noline);
%end;
%else %do;
  display=(noline)
  valueattrs=(style=&xfont_style size=8 weight=normal);
%end;
 
yaxis fitpolicy=split 
%if &NotDrawYaxisLabels=1 %then %do;
  display=(novalues noticks noline); 
%end;
%else %do;
  display=(noline)
  valueattrs=(Style=&yfont_style size=8 weight=normal); 
%end;
 
/*adjust colorbar postion*/       
/* gradlegend/integer position=bottom; */
/* gradlegend/position=right; */
/* gradlegend/position=bottom; */
gradlegend/position=&colorbar_position;
run;
ods listing close;
ods listing;
%mend;
/*Demo:
data a;
input x $ y $ z s;
cards;
a b 10 2
a c 1 0
a d 5 1
b b 4 2
b c 20 0
b d 15 1
a b 10 2
a c 1 0
a d 5 1
;

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

***Important;
***The simply sorting of dataset by xvar and yvar;
***will be effective for sorting the final heatmap;

%heatmap4longformatdsd(
dsdin=a,
xvar=x,
yvar=y,
colorvar=z,
fig_height=400,
fig_width=400,
outline_thickness=5,
user_yvarfmt=,
user_xvarfmt=,
colorbar_position=right,
colorrange=blue green red, 
yfont_style=normal, 
xfont_style=Italic
);

*If no colorvar supplied, the macro will draw a freq heatmap for xvar and yvar;
options mprint mlogic symbolgen;
%heatmap4longformatdsd(
dsdin=a,
xvar=x,
yvar=y,
colorvar= ,
fig_height=400,
fig_width=400,
outline_thickness=4,
colorbar_position=right,
colorrange=blue green red, 
yfont_style=normal, 
xfont_style=Italic
);

*If wanting to make the final heatmap in specific order, informat and format specific grps;
*sort yaxis;
*Here, do not use mkfmt4grpsindsd, as it use informat and format to process the var;
*Only format processed var can be correctly used by heatmap4longformatdsd;
*thus, please the macro mkfmt4grps_by_var;
%mkfmt4grpsindsd(
targetdsd=a,
grpvarintarget=y,
name4newfmtvar=new_y,
fmtdsd=a,
grpvarinfmtdsd=y,
byvarinfmtdsd=s,
finaloutdsd=x1
);

%heatmap4longformatdsd(
dsdin=x1,
xvar=x,
yvar=new_y,
colorvar=z,
fig_height=400,
fig_width=400,
outline_thickness=4,
user_yvarfmt=,
user_xvarfmt=
);


%mkfmt4grps_by_var(
grpdsd=a,
grp_var=y,
by_var=s,
outfmt4numgrps=nums2grps,
outfmt4chargrps=grps2nums
);

data x1;
set a;
new_y=input(y,nums2grps.);
run;
*Problems here, need to address later!;
%heatmap4longformatdsd(
dsdin=x1,
xvar=x,
yvar=new_y,
colorvar=z,
fig_height=400,
fig_width=400,
outline_thickness=4,
user_yvarfmt=grps2nums.,
user_xvarfmt=
);

*Make Zscore heatmapt demo:;
libname Out "J:\Coorperator_projects\Kidney_Microarray_Bob";
data Final_Corr;
set Out.PearsonCorr;
where PmMC013050<1e-3 and abs(mMC013050)>0.5;
run;

*Make heatmap for these genes associated with APOBEC1;
proc sql;
create table kd as 
select a.*,b.mMC013050 as R,b.PmMC013050 as P format=best31.
from out.kidney as a,
     Final_corr as b
where a.Gene_symbol=b.Gene_symbol
order by P;
*Calculate z-score of gene expression;
data kd;
set kd;
exp_mean=mean(of WK0_H001--WK4_H009);
exp_std=std(of WK0_H001--WK4_H009);
array X{*} WK0_H001--WK4_H009;
do i=1 to dim(X);
  X{i}=(X{i}-exp_mean)/exp_std;
end;
drop i;
run;
data kd1;
set kd;
keep Gene_symbol WK:;
run;
proc sort data=kd1 nodupkeys;by gene_symbol;
proc transpose data=kd1 out=kd_trans(rename=(_name_=Weeks COL1=exp_zscore));
var WK:;
by gene_symbol;
run;
proc sql;
create table kd_trans1 as
select a.*
from kd_trans as a,
     kd(obs=1000) as b
where a.Gene_symbol=b.Gene_symbol;
     
%heatmap4longformatdsd( 
dsdin=kd_trans1, 
xvar=Weeks, 
yvar=gene_symbol, 
colorvar=exp_zscore, 
fig_height=1000, 
fig_width=600, 
outline_thickness=0, 
user_yvarfmt=, 
user_xvarfmt=, 
colorbar_position=top, 
colorrange=blue green red, 
yfont_style=Italic,
xfont_style=normal,  
NotDrawXaxisLabels=0,
NotDrawYaxisLabels=1
); 


*/

