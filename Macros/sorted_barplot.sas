%macro sorted_barplot(
grpdsd=,	/*input dataset for making sorted barplots by the values of a grp variable*/
grp_var=ID, /*character groups for x-axis, thus if no extra color variable supplied for the last paramter colorgrp_var,
the macro will draw ALL bars in different colors, which sometimes is not informative!*/
xaxis_valuesrotate_type=diognal2,/*Draw the xaxis ticks in vertical, diognal, or diognol2*/
by_var=count, /*Numeric values for sorting bars and values on y-axis, which is used to sort the bars by its values from smallest to largest
and draw them according to this asending order from left to right in the figure*/
var4barplot=count,/*Default is to generate bar plot with numeric by_var; 
If the freq_count_var is not empty, it will use freq_count_var to generate bar plot*/
label4grp_var=ID,	/*Label for x-axis*/
label4y=, /*Label for y-axis*/
freq_count_var=,/*If not empty, it will use frequency count but no by_var for bar plot*/
stat4bar=sum, /*generate bar plot for the statistic of vara4barplot, such as mean, sum, median, Nmissing*/
fig_width=800,
fig_height=600,
colorbars_by_grp=1, /*Use different color for each bar; Note: need to be 1 when coloring bars by the last parameter colorgrp_var!*/
colorgrp_var= /*Provide a different var to color bars rather than using the default grp_var, which usually colors all bars in different colors;
If empty, the default by_var will be used as colorgrp_var*/
);
%mkfmt4grps_by_var(
grpdsd=&grpdsd,
grp_var=&grp_var,
by_var=&by_var,
outfmt4numgrps=x2y,
outfmt4chargrps=y2x
);
data &grpdsd.1;
set &grpdsd;
*format char grps to numeric grps;
new_&grp_var=input(&grp_var,x2y.);
run;
ods html image_dpi=300;
ods graphics /reset=all width=&fig_width height=&fig_height imagename="barsorted%randbetween(1,100)";

 proc sgplot data=&grpdsd.1 
 %if %length(&colorgrp_var)=0 %then %do; %str(noautolegend); %end;
noborder;
%if %length(&freq_count_var)>0 %then %do;
 vbar new_&grp_var/ freq=&by_var 	nooutline
                   %if &colorbars_by_grp=1 %then %do;
                     %if %length(&colorgrp_var)=0 %then %do;
                          group=new_&grp_var
                      %end;
                      %else %do;
													group=&colorgrp_var
                      %end;
                   %end;
;
%end;
%else %do;
 vbar new_&grp_var/stat=&stat4bar response=&var4barplot nooutline
                   %if &colorbars_by_grp=1 %then %do;
                     %if %length(&colorgrp_var)=0 %then %do;
                          group=new_&grp_var
                      %end;
                      %else %do;
													group=&colorgrp_var
                      %end;
                   %end;
name='bar_lgd';
%end;

 format new_&grp_var y2x.;
 label new_&grp_var="&label4grp_var";
 yaxis label="&label4y";
 xaxis valuesrotate=&xaxis_valuesrotate_type;
 keylegend 'bar_lgd'/noborder location=inside;
 run;

 %mend;

 /*Demo codes:;

 %sorted_barplot(
	grpdsd=uniq_snps_cnts_by_ID,
 grp_var=ID,
 by_var=count,
 var4barplot=count,
 label4grp_var=ID,
 label4y=Count,
freq_count_var=,
stat4bar=sum,
fig_width=800,
fig_height=600,
colorbars_by_grp=1
 );


 */



