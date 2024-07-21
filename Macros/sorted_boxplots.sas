%macro sorted_boxplots(
grpdsd=,	/*input dataset for making sorted barplots by the values of a grp variable*/
grp_var=ID, /*character groups for x-axis*/
by_var=count, /*Numeric values for sorting bars and values on y-axis*/
label4grp_var=ID,
label4y=Count,/*Y-axis label*/
stat4sort=mean /*mean, sum, median value of by_var to sort the boxplots*/
);
*Add summary statistics to the input dsd;
proc sort data=&grpdsd;
by 	&grp_var &by_var;
run;
proc summary data=&grpdsd(keep=&by_var &grp_var) mean sum median;
var &by_var;
by &grp_var;
output out=&grpdsd._summary 
           mean=mean4&by_var sum=sum4&by_var median=median4&by_var;
run;
proc sql;
create table &grpdsd.1 as 
select *
from &grpdsd(keep=&by_var &grp_var) 
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
Count=1;

proc sgplot data=&grpdsd.1;
vbox &by_var/group=new_&grp_var category=new_&grp_var 
                      %boxgrpdisplaysetting(by_cluster=0); 
format new_&grp_var y2x.;
label new_&grp_var="&label4grp_var"
          &by_var="&label4y";
*add count table, and no need for the option class, which is for boxplots with mulitple subgroups in each group;
xaxistable Count/stat=sum position=top;  
run;

 %mend;

 /*Demo codes:;
 ods graphics on/ reset=all width=1000 height=600 noborder;

 proc freq data=uniq_snps4celltypes noprint;
 table ID*celltype/list nocol norow nocum nopercent out=uniq_snps_cnts;
 run;

%sorted_boxplots(
grpdsd=uniq_snps_cnts,
grp_var=celltype, 
by_var=count, 
label4grp_var=Cell type,
label4y=Count,
stat4sort=mean
);


 */



