%macro sorted_barplot(
grpdsd=,	/*input dataset for making sorted barplots by the values of a grp variable*/
grp_var=ID, /*character groups for x-axis, thus if no extra color variable supplied for the last paramter colorgrp_var,
the macro will draw ALL bars in different colors, which sometimes is not informative!*/
xaxis_valuesrotate_type=diagonal2,/*Draw the xaxis ticks in vertical, diagonal, or diagonal2*/
xaxis_discval_order_by_data=0,/*Use presorted data by any vars and use the order of grp_var in the sorted data as the final order in the xaxis;
this option is very helpful when combining with colorbars_by_grp it can generate sorted bar plots 
by colorgrp_var and values that sorted by any other vars*/
by_var=, /*Numeric or character values for sorting bars and values on y-axis, which is used to sort the bars by its values from smallest to largest
and draw them according to this asending order from left to right in the figure;
Important: if the combination of grp_var and by_var resulting in the duplicates of grp_var, it is necessary to replace the 
by_var with EMPTY value, which means using only grp_var to remove duplciates of grp_var for making format that
is needed for the final xaxis ticks*/
var4barplot=count,/*Default is to generate bar plot with numeric by_var; 
If the freq_count_var is not empty, it will use freq_count_var to generate bar plot*/
label4grp_var=ID,	/*Label for x-axis*/
label4y=, /*Label for y-axis*/
freq_count_var=,/*If not empty, it will use frequency count but not by_var for bar plot*/
stat4bar=sum, /*generate bar plot for the statistic of vara4barplot, such as mean, sum, median, Nmissing*/
fig_width=800,
fig_height=600,
colorbars_by_grp=1, /*Use different color for each bar; Note: need to be 1 when coloring bars by the last parameter colorgrp_var!*/
colorgrp_var=, /*Provide a different var to color bars rather than using the default grp_var, which usually colors all bars in different colors;
If empty, the default by_var will be used as colorgrp_var*/
datalabel_var=, /*If value is not empty, the macro will add text values of the variable on the top of each bar*/
font4xticks=Courier, /*Assign monospaced font, such as Courier, when the xaxis ticks are derived by combining multiple vars*/
no_autolegend=0, /*Provide value 1 to remove auto legend for the bar colors*/
ymin=,	/*minimum value for yaxis*/
ymax=    /*maximum value for yaxis*/
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
ods graphics on /reset=all width=&fig_width height=&fig_height imagename="barsorted%randbetween(1,100)" noborder ;
*https://support.sas.com/resources/papers/proceedings19/3644-2019.pdf;
*Note: the addition of two options, nofill and noborder for the vbar, will NOT remove the border frame;
*It is the noborder that is added only after but not before the reset=all will remove the border frame;
 proc sgplot data=&grpdsd.1 noborder nowall 
 %if %length(&colorgrp_var)=0 %then %do; 
      %str(noautolegend); 
 %end;
;
%if %length(&freq_count_var)>0 %then %do;
 vbar new_&grp_var/ freq=&by_var 	nooutline nofill
                   %if &colorbars_by_grp=1 %then %do;
                     %if %length(&colorgrp_var)=0 %then %do;
                          group=new_&grp_var
                      %end;
                      %else %do;
													group=&colorgrp_var
                      %end;
                   %end;
  
%end;
%else %do;
 vbar new_&grp_var/stat=&stat4bar response=&var4barplot nooutline nofill
                   %if &colorbars_by_grp=1 %then %do;
                     %if %length(&colorgrp_var)=0 %then %do;
                          group=new_&grp_var
                      %end;
                      %else %do;
													group=&colorgrp_var
                      %end;
                   %end;
name='bar_lgd' 
%end;

%if %length(&datalabel_var)>0 %then %do;
%*Important: datalabel option needs to be effective when groupdisplay=cluster is set!;
 %str(datalabel= &datalabel_var GROUPDISPLAY=CLUSTER);
 %end;

;

 format new_&grp_var y2x.;
 label new_&grp_var="&label4grp_var";
 yaxis label="&label4y" 
 %if %length(&ymin)>0 %then %do;
  min=&ymin
  %end;
 %if %length(&ymax)>0 %then %do;
  max=&ymax
 %end;
;
 xaxis valuesrotate=&xaxis_valuesrotate_type valueattrs=(family="&font4xticks" style=normal weight=bold size=8) 
%if &xaxis_discval_order_by_data=1 %then %do;
   DISCRETEORDER=DATA
%end;
;
%if &no_autolegend=0 %then %do;
 keylegend 'bar_lgd'/noborder location=inside;
 %end;

 run;

 %mend;

 /*Demo codes:;

 ******************Demo 1 codes:;

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

 *More advanced use of the macro;
 *Generate bars sorted by a group var and a value var that is presorted by other vars ;
 *This is like the cancer mutation burden plots by different cancer type and mutation burden values;

 ods html image_dpi=300 ;
ods graphics on /reset=all;
proc sort data=snp_gene_grps;by top_grp count;
%sorted_barplot(
grpdsd=snp_gene_grps,
grp_var=snp_gene, 
xaxis_valuesrotate_type=diagonal2,
xaxis_discval_order_by_data=1,
by_var=count, 
var4barplot=count,
label4grp_var=SNP gene pair,	
label4y=Number of genes,
freq_count_var=
stat4bar=sum, 
fig_width=1000,
fig_height=400,
colorbars_by_grp=1, 
colorgrp_var=top_grp
); 

 ******************Demo 2 codes for generating frequency bars with customized filters;

 *Note that the tag var is created to indicate the number of tissues showing nominal significant association;
 data tops2;
set tops2;
tag=0;
if logP>1.3 then tag=1;
run;


%leftalign4catstr(
dsdin=tops2,
vars4cat=gene_name gwas,
combinedVar=comb_gene_gwas,
dsdout=tops3,
add_extra_sep_et_end=1
);
proc sort data=tops3;by gwas logP;

**********************************Bar plots are with issues**************************;
 *Generate bars to display number of tissues showing nominal significance for each gene-GWAS pairs;
%sorted_barplot(
grpdsd=tops3,	
grp_var=comb_gene_gwas, 
xaxis_valuesrotate_type=diagonal2,
xaxis_discval_order_by_data=1,
by_var=gwas,
var4barplot=tag,
label4grp_var=Gene GWAS pair,	
label4y=# of tissues with P<0.05,
freq_count_var=,
stat4bar=sum, 
fig_width=1200,
fig_height=300,
colorbars_by_grp=1,
colorgrp_var=,
datalabel_var=tag
);

*Generate bars to illustrate number of gene-gwas pairs passed the nominal significance in each tissue;
 *Note: assign empty value to by_var when only there are duplicates in the grp_var;
%sorted_barplot(
grpdsd=tops3,	
grp_var=tissue,
xaxis_valuesrotate_type=diagonal2,
xaxis_discval_order_by_data=1,
by_var=, 
var4barplot=tag,
label4grp_var=tissue,
label4y=# of gene-GWAS pairs with P<0.05,
freq_count_var=,
stat4bar=sum,
fig_width=1200,
fig_height=300,
colorbars_by_grp=1, 
colorgrp_var=,
datalabel_var=tag,
 no_autolegend=1
);



 */



