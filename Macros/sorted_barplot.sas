%macro sorted_barplot(
grpdsd=,	/*input dataset for making sorted barplots by the values of a grp variable*/
grp_var=ID, /*character groups for x-axis*/
by_var=count, /*Numeric values for sorting bars and values on y-axis*/
var4barplot=count,/*Default is to generate bar plot with numeric by_var; 
If the freq_count_var is not empty, it will use freq_count_var to generate bar plot*/
label4grp_var=ID,	/*Label for x-axis*/
label4y=, /*Label for y-axis*/
freq_count_var=,/*If not empty, it will use frequency count but no by_var for bar plot*/
stat4bar=sum, /*generate bar plot for the statistic of vara4barplot, such as mean, sum, median, Nmissing*/
fig_width=800,
fig_height=600,
colorbars_by_grp=1 /*Use different color for each bar*/
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

ods graphics /reset=all width=&fig_width height=&fig_height;

 proc sgplot data=&grpdsd.1 noautolegend ;
%if %length(&freq_count_var)>0 %then %do;
 vbar new_&grp_var/ freq=&by_var 	nooutline
                    %if &colorbars_by_grp=1 %then %do;
                      group=new_&grp_var
                    %end;
;
%end;
%else %do;
 vbar new_&grp_var/stat=&stat4bar response=&var4barplot nooutline
                   %if &colorbars_by_grp=1 %then %do;
                     group=new_&grp_var
                   %end;
;
%end;

 format new_&grp_var y2x.;
 label new_&grp_var="&label4grp_var";
 yaxis label="&label4y";
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



