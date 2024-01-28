%macro sorted_barplot(
grpdsd=,	/*input dataset for making sorted barplots by the values of a grp variable*/
grp_var=ID, /*character groups for x-axis*/
by_var=count, /*Numeric values for sorting bars and values on y-axis*/
label4grp_var=ID,	/*Label for x-axis*/
label4y= /*Label for y-axis*/
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

 proc sgplot data=&grpdsd.1;
 vbar new_&grp_var/ freq=&by_var group=new_&grp_var;
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
 label4grp_var=ID,
 label4y=Count
 );


 */



