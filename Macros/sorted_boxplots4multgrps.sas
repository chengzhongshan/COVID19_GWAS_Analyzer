%macro sorted_boxplots4multgrps(
grpdsd=,	/*input dataset for making sorted barplots by the values of a grp variable*/
grp_var=ID, /*character groups for x-axis*/
subgrp_var=SubID,/*subgrp variable for boxplot cluster at each x-axis group variable*/
by_var=count, /*Numeric values for sorting bars and values on y-axis*/
label4grp_var=ID,
label4y=Count,/*Y-axis label*/
stat4sort=mean, /*mean, sum, median value of by_var to sort the boxplots*/
stat4spec_grp=grp1,/*Sort the by_var value for a specific sub group of subgrp_var with the input value*/
add_cnt_tb=0, /*Add sample size count table on the top of boxplot*/
fig_width=600,
fig_height=600,
outputfmt=png, /*png, jpg, or svg*/
yaxis_cmd=%str(type=log logbase=10)	 /*Customize yaxis tickets*/
);
*Add summary statistics to the input dsd;
proc sort data=&grpdsd;
by 	&grp_var &by_var;
run;
proc summary data=&grpdsd(keep=&by_var &grp_var &subgrp_var) mean sum median;
where &subgrp_var="&stat4spec_grp";
var &by_var;
by &grp_var;
output out=&grpdsd._summary 
           mean=mean4&by_var sum=sum4&by_var median=median4&by_var;
run;
proc sql;
create table &grpdsd.1 as 
select *
from &grpdsd(keep=&by_var &grp_var &subgrp_var) 
natural left join
&grpdsd._summary
;


%let new_by_var=&stat4sort.4&by_var;
%mkfmt4grps_by_var(
grpdsd=&grpdsd.1,
grp_var=&grp_var,
by_var=&new_by_var,
outfmt4numgrps=x2y,
outfmt4chargrps=y2x
);

data &grpdsd.1;
set &grpdsd.1;
*format char grps to numeric grps;
new_&grp_var=input(&grp_var,x2y.);
%if &add_cnt_tb=1 %then %do;
N=1;
%end;

ods graphics /reset=all width=&fig_width height=&fig_height outputfmt=&outputfmt noborder;

proc sgplot data=&grpdsd.1;
*Note: category represents middle x-axis and group indicates cluster group for each category on x-axis;
vbox &by_var/category=new_&grp_var group=&subgrp_var
                      %boxgrpdisplaysetting(by_cluster=1); 
format new_&grp_var y2x.;
label new_&grp_var="&label4grp_var"
          &by_var="&label4y";
%if &add_cnt_tb=1 %then %do;
*add count table, and no need for the option class, which is for boxplots with mulitple subgroups in each group;
xaxistable N/stat=sum position=top;  
%end;
yaxis &yaxis_cmd;
run;

 %mend;

 /*Demo codes:;
proc import datafile="E:\scASE\SNP_ReadCNTs4celltype4all_genes.csv" dbms=csv out=all_genes replace;
guessingrows=max;

proc import datafile="E:\scASE\SNP_ReadCNTs4celltype4imprinted_genes.csv" dbms=csv out=tgt_genes replace;
guessingrows=max;
run;

data combined;
length grp $30.;
set all_genes(in=a) tgt_genes(in=b);
if a then grp="All genes";
else grp="Imprinted genes";
Count=Frequency_Count+0;
label grp="Gene group";
run;

%sorted_boxplots4multgrps(
grpdsd=combined,	
grp_var=celltype,
subgrp_var=grp,
by_var=count,
label4grp_var=Single cell type,
label4y=# of SNPs with reads > 10 of a sample,
stat4sort=mean,
stat4spec_grp=Imprinted genes,
add_cnt_tb=0, 
fig_width=1000,
fig_height=400,
outputfmt=png
);

 */



