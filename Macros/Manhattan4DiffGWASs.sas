%global chr_var;*Make sure we can asign new vale to it in some IF condition;
*This will be used by color macros for different chromosomes;
%global dotsize;

%macro Manhattan4DiffGWASs(
dsdin=,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=,/*Position variable for markers, such as SNPs*/
chr_var=,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=2,/*The dot size for scatter plots*/
_logP_topval=10, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=2,/*Customize the step for all y-axis tikets*/
fig_width=1200,
fig_height=500,
fontsize=3,
flip1stGWAS_signal=1, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=,/*Provide customized uniq colors, such as cx0072bd and others with the prefix cx;
If left empty, the default unique colors included in the macro will be used!*/
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan, /*a prefix used to label the output figure*/
angle4xaxis_label=40, /*Adjust the angle of xaxis group labels*/
Use_scaled_pos=1, /*Default is to draw manhattan plot with fake positions by group in even distance;
Provide value 1 to draw the plot in scaled and uneven distance relative to its real position values!
This will be helpful when draw top hits local manhattan plots!
*/
sep_chr_grp=0, /*Default is not to add lines to separate x-axis chromosomal groups;
Provide value 1 to add lines to separate each chromosomal group*/ 
xgrp_y_pos=-1.5, /*Asign the y-axis value for all x-axis group labels;
It is necessary to adjust the value if the default value is out of range;
Try to use -1 to replace -1.5 if the above issue occurred!*/
yoffset_setting=%str(offset=(2,0.5)), /*This macro var is used to extend the bottom and upper y-axis;
which is especially helpful when the position of x-axis group labels assigned by xgrp_y_pos is 
out of the default offset of y-axis */

/*Important parameters for drawing local Manhattan pltos*/
draw_local_Manhattan=0,/*Default is to draw genome-wide Manhattan plot; if supplying value 1, the macro will draw local
Manhattano around target SNPs when the macro var target_SNPs is provided or top hits if the macro var target_SNPs
is empty and the macro var top_hit_thresd is supplied with specific association p threshold, such as p < 1e-6*/
snp_var=rsid,/*It is necessary to have snp_var supplied when drawing local Manhattan plot*/
target_SNPs=,/*Default is empty; please provide rsid that can be matched with the snp macro variable*/
Keep_order_of_target_SNPs=0, /*Draw local Manhattan plot according to the order of target SNPs
Note: need to set this macro with value 1 if drawing local Manhattan plots for target SNPs or top hits, 
which means if either target_SNPs or top_hit_thresd is not empty, please assign value 1 to this macro var!
When draw genome-wide Manhattan plots, it is required to assign value 1 to this macro var.*/
top_hit_thresd=,/*provide a p value threshold to only draw local Manhattan plot for the smallest 
top hit around a specific genomic window,such as p < 1e-6 within a window of 1e7 bp*/
dist4get_smallest_top_hit=1e7, /*Select the smallest top SNP around a genomic window of the supplied distance in bp*/
only_get_top_hit4n_th_gwas=0 /*The parameter enables the macro to focus on top hits from specific gwas represented by 
its order starting from 1 to n for the 1st gwas and other gwass inferred by their supplied P variables; the default value 0 means
to query all gwas top hits; if only want to query top hits from the 1 gwas, please supply value 1, and this applicable to 
other gwass if the correct numeric order for the gwas is supplied here!*/
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

%if %length(&Other_P_vars)=0 %then %do;
    %put This macro is designed for working with >= 2 GWAS and needs to have the macro var Other_P_vars supplied with a variable of P value for the 2nd GWAS;
	%abort 255;
%end;

%if %varexist(ds=&dsdin,var=&chr_var) = 0 %then %do;
					 %put Input chr var &chr_var does not exit!;
           %abort 255;
%end;

%if %varexist(ds=&dsdin,var=&pos_var) = 0 %then %do;
					 %put Input position var &pos_var does not exit!;
           %abort 255;
%end;

%if %varexist(ds=&dsdin,var=&P_var) = 0 %then %do;
					 %put Input P value var for the 1st GWAS does not exit!;
           %abort 255;
%end;



*Subset GWAS data for target regions with top association signals passed specific p threshold;
*or just draw the local Manhattan for these target SNPs with specific window size; 
%if &draw_local_Manhattan=1 %then %do;
       *Draw local Manhattan plot for target SNPs;
			 %if 	(%length(&target_SNPs)>0 and %length(&top_hit_thresd)=0) %then %do;
					%put We will extract association signals around these target snps and draw local Manhattan plot;
           %put Your target SNPs are &target_SNPs;
          *Get target SNPs; 
          %get_tgt_hits4Manhattan(
           dsdin=&dsdin,
           snp_var=&snp_var,
           chr_var=&chr_var,
           pos_var=&pos_var,
           p_var=&P_var,
           dsdout=_tgthits_,
           target_snps=&target_snps, 
           keep_target_snps_order=&Keep_order_of_target_SNPs,
           dist4get_uniq_top_hit=&dist4get_smallest_top_hit 
           );
          *Note: the above macro will generate new variable tag_snp and a global macro variable _chr_colors_;
          *which will be used to draw Manhattan plots by chr, and it is necessary to reset these macro var values for making local Manhattan plot;
          %let dsdin=_tgthits_;
           *Draw local Manhattan plots by sorted order of target SNPs;
           %let chr_var=tag_snp;
           %if &Keep_order_of_target_SNPs=1 %then %do;
           *Draw local Manhattan plots by keeping the original order of target SNPs;
           %let chr_var=num_grps;
           %end;

          %let uniq_colors=&_chr_colors_;
       %end;
       %*Draw local Manhattan plot for top hits passed a specific p threshold;
       %else %do;
           %if %length(&top_hit_thresd)=0 %then %let top_hit_thresd=1e-6;
           %let top_snps=;
           %local _mh_;
		   %do _mh_= 1 %to %sysevalf(%ntokens(&Other_P_vars)+1);
			 %if &only_get_top_hit4n_th_gwas=0 %then %do;
             %get_top_hits4Manhattan(
              dsdin=&dsdin,
              snp_var=&snp_var,
              chr_var=&chr_var,
             pos_var=&pos_var,
             p_var=%scan(&P_var &Other_P_vars,&_mh_,%str( )),
             dsdout=_tophits_&_mh_,
             p_thrsd=&top_hit_thresd, 
            dist4get_uniq_top_hit=&dist4get_smallest_top_hit
             );
/*             *Note: the above macro will create new variable tag_snp and a global macro var _top_snps_ that will be used to capture these top SNPs;*/
/*             %let top_snps=&top_snps &_top_snps_;*/
			%end;
			%else %if (&_mh_=&only_get_top_hit4n_th_gwas) %then %do;

             %get_top_hits4Manhattan(
              dsdin=&dsdin,
              snp_var=&snp_var,
              chr_var=&chr_var,
             pos_var=&pos_var,
             p_var=%scan(&P_var &Other_P_vars,&_mh_,%str( )),
             dsdout=_tophits_&_mh_,
             p_thrsd=&top_hit_thresd, 
            dist4get_uniq_top_hit=&dist4get_smallest_top_hit
             ); 
 
			%end;
           %end;
					 %put We will extract associaiton signals around these top SNPs within a genomic window of &dist4get_smallest_top_hit bp that pass the p value threshold of &top_hit_thresd;
           %put These top SNPs are &top_snps;
            data tophits_all;
            set _tophits_:;
            run;
           *Reset these macro var values for making local Manhattan plot;
            %let dsdin=tophits_all;
            *Draw local Manhattan plots by sorted order of target SNPs;
            %let chr_var=tag_snp;
            proc sql noprint;
            select distinct cls into: uniq_colors separated by ' '
            from tophits_all 
            order by tag_snp;
       %end;
%end;

*Check &chr_var type for preparing of making alternative var _chr_ for plotting;
*Note: will create a global var: var_type, which can be used in other macro;
%check_var_type(
dsdin=&dsdin,
var_rgx=&chr_var
);
%put Created a global var for chr, its type of which is &var_type;
/*%put the macro chr_var is &chr_var;*/
/*%abort 255;*/

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

*Sorting the gwas will slow down the macro;
/*
proc sort data=&dsdin;
by &chr_var &pos_var;
run;
*/

%if &gwas_sortedby_numchrpos=0 %then %do;
proc sort data=&dsdin;
by &chr_var &pos_var;
run;
%end;

%if %sas_dsd_exist(sasdsd=&dsdin)=0 or %totobsindsd(mydata=&dsdin)=0 %then %do;
    %put Your input dataset &dsdin does not exist or is empty;
    %abort 255;
%end;
 

%let nrows=%rows_in_sas_dsd(test_dsd=&dsdin);
%put There are &nrows in your dataset;

%if &Use_scaled_pos=0 %then %do;
*Here we will use fake positions with an even gap to draw manhattan plot;
/*For EWAS;*/
%if (&nrows lt 100000 and &nrows gt 30000) %then %do;
data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ / 1e2 ;/*This part will affect the Xaxis dramatically*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;
/*For local EWAS or GWAS;*/
%else %if (&nrows lt 30000 and &nrows gt 4000) %then %do;

data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ /2 ;/*This part will affect the Xaxis dramatically*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;
/*For local EWAS or GWAS;*/
%else %if &nrows le 4000 %then %do;
data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ ;/*This part will affect the Xaxis dramatically*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;
/*For GWAS*/
%else %do;
data manhattan ;
set &dsdin;
Fake_position=1; 
Fake_position + _n_ / 1e3 ;/*This part will affect the Xaxis dramatically*/;
/*where &chr_var between 1 and 24;*/
/*where &chr_var >=1;*/
run;
%end;

%end;

%else %do;
*Here we will use fake positions with scaled and uneven gap  to draw manhattan plot;
%add_fake_pos_by_grp4nonnegvars(
dsdin=&dsdin,
axis_var=&pos_var,
axis_grp=&chr_var,
new_fake_axis_var=Fake_position,
dsdout=manhattan,
axis_step=1,
concise_output=1,
reset_1st_value_as_one=1
);
%end;


data manhattan;
set manhattan(where=(&P_var^=.));
%if (&logP=1) %then %do;
logp=-log10(&P_var);
%end;
%else %do;
logp=&P_var;
%end;
run;

*Sorting the gwas will slow down the macro;
/*
proc sort data=manhattan;
by &chr_var Fake_position;
run;
*/

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

*A potential bug here especially when there are a lot of SNPs with missing p values;
*were removed from the data set before calculating the mean of these positions;
*Try to generate a temporary data set;
proc sort data=manhattan(keep=&chr_var Fake_position) out=_manhattan_ nodupkeys;
by &chr_var Fake_position;
run;
proc sql;
create table _manhattan_ as
select *
from _manhattan_
group by &chr_var
having Fake_position=min(Fake_position) or Fake_position=max(Fake_position);
*If the above invite some bugs, it is feasible to use the data set manhattan to replace _manhattan_;
proc summary data=_manhattan_ nway;
%if &Keep_order_of_target_SNPs=1 %then %do;
*Draw local Manhattan plots by keeping the original order of target SNPs;
/*class &chr_var tag_snp;*/
*No need to add tag_snp as &chr_var is updated as tag_snp;
class &chr_var;
%end;
%else %do;
class &chr_var;
%end;
var Fake_position;
/*output out=mbp mean=;*/
/*output out=mbp mean= min=min max=max;*/
output out=mbp mean=;
run;

*The _mid_ is the same as the mean position;
/*data mbp;*/
/*set mbp;*/
/*_mid_=(max-min)/2 + min;*/
/*run;*/

 
* annotate data set used to add x-axis labels
"manually" add the frame around the graph
possibly add a horizontal reference line
;
data anno ;
length color $10. text $20.;
*Note: the position will decide where to put the text;
*position '1': put text under the position and left adjusted;
*position '2': put text at the middle of the position and left adjusted;
*position '3': put text above the position and left adjusted;
*position '4': put text under the position and center adjusted;
%if "&var_type"="2" or &Keep_order_of_target_SNPs=1 %then %do;
retain position '4' xsys ysys '2' y &xgrp_y_pos function 'label' text 'xx'  angle &angle4xaxis_label;
%end;
%else %do;
retain position '8' xsys ysys '2' y 0 function 'label' text 'xx' ;
%end;
do until (last1);
  %if &Keep_order_of_target_SNPs=1 %then %do;
  *Draw local Manhattan plots by keeping the original order of target SNPs;
/*   set mbp (keep = Fake_position &chr_var  tag_snp) end=last1;*/
   *No need to add tag_snp as &chr_var is tag_snp when keep_order_of_target_SNPs is true;
     set mbp (keep = Fake_position &chr_var) end=last1;
  %end;
  %else %do;
   set mbp (keep = Fake_position &chr_var) end=last1;
  %end;
   x = round(Fake_position) ;
   *This step can be modified to remove the x-axis group labels by asigning empty str to text;
   %if "&var_type"="2" %then %do;
   *text="";
    text=put(&chr_var,Xaxis_var_label.);
/*       text=cat(&chr_var);*/
   %end;
   %else %do;
         %if &Keep_order_of_target_SNPs=1 %then %do;
           *Draw local Manhattan plots by keeping the original order of target SNPs;
						text = tag_snp;
         %end;
         %else %do;
            text = cat(&chr_var);
            if text="20" or text="22"  then text=" ";
         %end;
   %end;
   output;
end;
 
* top of frame;
xsys = '1'; ysys = '1'; function = 'move'; x = 0; y=100; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
* bottom of frame;
xsys = '1'; ysys = '1'; function = 'move'; x = 0; y=0; output;
xsys = '2'; function = 'draw'; x = &maxbp ; output;
 
* horizontal reference line (if needed for 5x10-08);
xsys = '1'; ysys = '2'; function = 'move'; x = 0; y=&_logP_topval; output;
xsys = '2'; function = 'draw'; x = &maxbp ; line=1; size=3; color="&refline_color_4zero";output;
%if (&flip1stGWAS_signal=0) %then %do;
xsys = '1'; ysys = '2'; function = 'move'; x = 0; y=&gwas_thrsd; output;
xsys = '2'; function = 'draw'; x = &maxbp ; line=2; size=1; color="&thrsd_line_color";output;
%end;
%else %do;
xsys = '1'; ysys = '2'; function = 'move'; x = 0; y=&_logP_topval-&gwas_thrsd; output;
xsys = '2'; function = 'draw'; x = &maxbp ; line=2; size=1; color="&thrsd_line_color";output;
%end;

%do ri=1 %to %ntokens(&Other_P_vars);

%if &ri < %ntokens(&Other_P_vars) %then %do;
xsys = '1'; ysys = '2'; function = 'move'; x = 0; y=&_logP_topval+&_logP_topval*&ri; output;
xsys = '2'; function = 'draw'; x = &maxbp ;  line=1; size=3; color="&refline_color_4zero";output;
%end;

xsys = '1'; ysys = '2'; function = 'move'; x = 0; y=&gwas_thrsd+&_logP_topval*&ri; output;
xsys = '2'; function = 'draw'; x = &maxbp ; line=2; size=1; color="&thrsd_line_color";output;

%end;

run;

 
* reset all then set some graphics options;
%let max_yaxis_val=%sysevalf(%ntokens(&Other_P_vars)*&_logP_topval + &_logP_topval);
*If put reset=all inside the command of goptions, the title will be removed;
*It is necessary to reset all here, otherwise, the figure may be distorted;
*Albany AMT is equivalent to Arial in SAS;
goptions reset=all ftext="Albany AMT" htext=&fontsize gunit=pct 
         dev=gif xpixels=&fig_width ypixels=&fig_height gsfname=gout;

 
* make some room around the plot (white space);
title1 ls=2;
title2 a=90 ls=2;
title3 a=-90 ls=2;
footnote1 ls=2;
 
* let SAS choose the colors;
* use h=5 to set dot size for the plot;
%if &use_uniq_colors=0 %then %do;
symbol1 v=dot r=46 h=&dotsize;
%end;
%else %do;
 %if %length(&uniq_colors)=0 %then %do;
      *Use default unique colors;
      %uniqcolors;
  %end;
   %else %do;
     *Use customized unique colors;
     %uniqcolors(inputcolors=&uniq_colors);
    %end;
%end;

* two alternating colors;
* gray-scale;
*%twocolors(gray33,graycc);
* blue and blue-green;
*%twocolors(cx2C7FB8,cx7FCDBB);
 
*If the y_axix_step is larger than the top _logp_topval;
*Use step value 2 instead;
%if %sysevalf(2*&y_axix_step)>=&_logp_topval %then %do;
					 %put Your assigned y-axis step value &y_axix_step is too large and even larger than half of the top association value;
           %put The macro will reset the y-axis step value as 2!;
           %let y_axix_step=2;
%end;

* suppress drawing of any x-axis feature;
axis1 value=none major=none minor=none label=none style=0;
* rotate y-axis label and asign font as f='Albany AMT';
axis2 label=(angle=90 "-Log10(p)" f=Arial h=&fontsize) 
     order=(0 to  &max_yaxis_val by &y_axix_step)	 &yoffset_setting
      value=(f=Arial h=&fontsize
             %do _pi_=0 %to %ntokens(&Other_P_vars);
                %if (&flip1stGWAS_signal=1 and &_pi_=0) %then %do;
                  %do _ti_=&_logp_topval %to &y_axix_step %by -&y_axix_step;
                      "&_ti_"
                   %end;              
                 %end;
                 %else %do;
                  %do _ti_=0 %to %sysevalf(&_logp_topval-&y_axix_step) %by &y_axix_step;
                      "&_ti_"
                   %end;
                  %end;
               %end;
                ' '
                  );
 
* destination for the plot;
filename gout "./&outputfigname..gif";
 
* use PROC GPLOT to create the plot;
*Add format for customized &chr_var labels;
*Make sure to remove nolegend;

data manhattan;
set manhattan;
*Further remove signals with logP<1.3, which will save space and prevent the reference lines covered by these signals with logP<1.3;
if logP<&rm_signals_with_logP_lt then logP=.;
if logp>&_logP_topval then logp=&_logP_topval;

%if (&flip1stGWAS_signal=1) %then %do;
logp=&_logP_topval-logp;
%end;


%do _mi_=1 %to %ntokens(&Other_P_vars);
 logp&_mi_=-log10(%scan(&Other_P_vars,&_mi_,' '));
if logP&_mi_<&rm_signals_with_logP_lt then logP&_mi_=.;
 if logp&_mi_>&_logP_topval then logp&_mi_=&_logP_topval ;
if logp&_mi_^=. then logp&_mi_=logp&_mi_+&_logP_topval*&_mi_;
%end;

run;

proc transpose data=manhattan out=manhattan(rename=(col1=logP) drop=_name_);
var logp:;
by &chr_var Fake_position;
run;

*Get the max position for each chr;
proc sql noprint;
select distinct Fake_position into: min_fk_pos separated by ' '
from manhattan
group by &chr_var
having fake_position=min(fake_position);
*Remove the first element in the list;
%select_element_range_from_list( 
list=&min_fk_pos, 
st=2, 
end=%ntokens(&min_fk_pos), 
sublist=new_min_fk_pos, 
sep=%str( ) 
); 


%if "&var_type"="2" or &Keep_order_of_target_SNPs=1 %then %do;

/*Note: the offset setting will make the legend move left when value is negative!*/
*https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/graphref/p0anvu6ux4d0ijn1mt06fn9yl0wx.htm#p18f31f18e6elan1ge5bb2pjiv34;
*Note: asign empty string for the label of the legend;
legend1 across=10 down=2 repeat=1 label=(height=4 position=top justify=center ' ')
        value=(height=2) shape=symbol(2,2) offset=(1pct)
        position=(bottom center outside);
*The offset=(0,0)cm or offset=(2pct) will affect the left position of the legend;
*See how to customize legend:;
*https://support.sas.com/resources/papers/proceedings/proceedings/forum2007/163-2007.pdf;

%if &sep_chr_grp=1 %then %do; 
%let maxbp=&maxbp &new_min_fk_pos;
%end;

proc gplot data=manhattan;
plot logp*Fake_position=&chr_var 
 /  
                 haxis = axis1
                 vaxis = axis2
                 href  = &maxbp 
                 annotate = anno
                nolegend
		            noframe
/*		         legend=legend1*/
;
%if &Keep_order_of_target_SNPs^=1 %then %do;
format &chr_var Xaxis_var_label.;
%end;
label Fake_position="Groups"
      &chr_var="Legends of groups";
run;

*Also keep a copy of the dataset for further plotting with the macro;
data _tgthits_;
set _tgthits_;
drop tag_snp;
run;

%end;

%else %do;
proc gplot data=manhattan;
plot1 logp*Fake_position=&chr_var
 / 
                 haxis = axis1
                 vaxis = axis2
                 href  = &maxbp
                 annotate = anno
                 nolegend
		         noframe
;
run;
%end;

*This will enable the macro generate one figure by proc gplot in SAS OnDemand for Academics;
*Otherwise, there would be two duplicated Manhattan plots;
/* %return; */
*return does not work, and only quit dose!;
%put After successfully generate manhattan plot, the macro will quit to prevent from two duplicated Manhattan plots printed!;
quit;

%mend;

******************Sub macros**********************;
* macro that can be used later to generate symbols for plots with two alternating colors;
%macro twocolors(c1,c2);
%do j=1 %to 23 %by 2;
symbol&j v=dot c=&c1;
symbol%eval(&j+1) v=dot c=&c2;
%end;
%mend;

%macro uniqcolors(inputcolors=);

%if %length(&inputcolors)=0 %then %do;
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

*repeat the symbols until to 46, in case of drawing local manhattan plots with more than 23 groups;
*If there are more than 46 groups, the manhattan plots will be too busy!;
symbol24 v=dot h=&dotsize c=cx0072bd;
symbol25 v=dot h=&dotsize c=cxd95319;
symbol26 v=dot h=&dotsize c=cxedb120;
symbol27 v=dot h=&dotsize c=cx7e2f8e;
symbol28 v=dot h=&dotsize c=cx77ac30;
symbol29 v=dot h=&dotsize c=cx4dbeee;
symbol30 v=dot h=&dotsize c=cxa2142f;
symbol31 v=dot h=&dotsize c=cx0072bd;
symbol32 v=dot h=&dotsize c=cxd95319;
symbol33 v=dot h=&dotsize c=cxedb120;
symbol34 v=dot h=&dotsize c=cx7e2f8e;
symbol35 v=dot h=&dotsize c=cx77ac30;
symbol36 v=dot h=&dotsize c=cx4dbeee;
symbol37 v=dot h=&dotsize c=cxa2142f;
symbol38 v=dot h=&dotsize c=cx0072bd;
symbol39 v=dot h=&dotsize c=cxd95319;
symbol40 v=dot h=&dotsize c=cxedb120;
symbol41 v=dot h=&dotsize c=cx7e2f8e;
symbol42 v=dot h=&dotsize c=cx77ac30;
symbol43 v=dot h=&dotsize c=cx4dbeee;
symbol44 v=dot h=&dotsize c=cxa2142f;
symbol45 v=dot h=&dotsize c=cx0072bd;
symbol46 v=dot h=&dotsize c=cxd95319;
%end;
%else %do;
 %local _ci_ ncls;
 %let ncls=%ntokens(&inputcolors);
 %do _ci_=1 %to &ncls;
    symbol&_ci_ v=dot h=&dotsize c=%scan(&inputcolors,&_ci_,%str( ));
 %end;
%end;
%mend;


/*Demo codes:;
*The easiest way to draw local Manhattan plots for target SNPs;
 %Manhattan4DiffGWASs(
    dsdin=D.GWAS1_vs_2,
    pos_var=pos,
    chr_var=chr,
    P_var=GWAS1_P,
    Other_P_vars=GWAS2_P Pval,
    rm_signals_with_logP_lt=0,
    uniq_colors=&_chr_colors_,
    flip1stGWAS_signal=0,
    sep_chr_grp=1,
    fig_width=1200,
    fig_height=600,
    angle4xaxis_label=90,
    xgrp_y_pos=-0.2,
    yoffset_setting=%str(offset=(25,0.5)),
    draw_local_Manhattan=1,
    target_snps=rs16831827 rs13050728 rs13079478 rs14334143 rs2166172 rs2269899 rs622568 rs920065566
);
*If some of the above target SNPs are not the top hits in the searching genomic window, it is better to get these top hits;
*Now get top hits from the subset dataset _tgthits_ generated internally by the above macro;
%Manhattan4DiffGWASs(
    dsdin=_tgthits_,
    pos_var=pos,
    chr_var=chr,
    P_var=GWAS1_P,
    Other_P_vars=GWAS2_P Pval p,
    rm_signals_with_logP_lt=0,
    dotsize=1.5,
    uniq_colors=&_chr_colors_,
    flip1stGWAS_signal=0,
    sep_chr_grp=1,
    fig_width=1200,
    fig_height=600,
    angle4xaxis_label=90,
    xgrp_y_pos=-0.2,
    yoffset_setting=%str(offset=(20,0.5)),
    draw_local_Manhattan=1,
    target_snps=,
    top_hit_thresd=1e-6,
    dist4get_smallest_top_hit=1e8
);

*Only focus on top hits in the GWAS;

%GRASP_COVID_Hosp_GWAS_Comparison(
  gwas1=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B1_ALL_20201020.b37.txt.gz,
  gwas2=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz,
  outdir=%sysfunc(getoption(work)),
  mk_manhattan_qqplots4twoGWASs=0
  );

 %Manhattan4DiffGWASs(
    dsdin=GWAS1_vs_2,
    pos_var=pos,
    chr_var=chr,
    P_var=GWAS1_P,
    Other_P_vars=GWAS2_P Pval,
    flip1stGWAS_signal=0
   );
 
*Get top SNP and draw local Manhattan plot using the same macro; 
%get_top_hits4Manhattan(
dsdin=GWAS1_vs_2,
snp_var=rsid,
chr_var=chr,
pos_var=pos,
p_var=pval,
dsdout=tophits,
p_thrsd=5e-7, 
dist4get_uniq_top_hit=1e6 
);
*Note: the above macro will generate a global macro variable:;
*_chr_colors_, which will be used to draw Manhattan plots by chr;

%Manhattan4DiffGWASs(
    dsdin=tophits,
    pos_var=pos,
    chr_var=tag_snp,
    P_var=GWAS1_P,
    Other_P_vars=GWAS2_P Pval,
    rm_signals_with_logP_lt=0,
    uniq_colors=&_chr_colors_,
    flip1stGWAS_signal=0,
    sep_chr_grp=1,
    fig_width=1200,
    fig_height=600,
    angle4xaxis_label=90,
    xgrp_y_pos=-0.2,
    yoffset_setting=%str(offset=(25,0.5)) 
 );

*Get target SNPs and draw local Manhattan plot using the same macro; 
%get_tgt_hits4Manhattan(
dsdin=GWAS1_vs_2,
snp_var=rsid,
chr_var=chr,
pos_var=pos,
p_var=pval,
dsdout=tgthits,
target_snps=rs2564978 rs7850484, 
dist4get_uniq_top_hit=1e6 
);
*Note: the above macro will generate a global macro variable:;
*_chr_colors_, which will be used to draw Manhattan plots by chr;

%Manhattan4DiffGWASs(
    dsdin=tgthits,
    pos_var=pos,
    chr_var=tag_snp,
    P_var=GWAS1_P,
    Other_P_vars=GWAS2_P Pval,
    rm_signals_with_logP_lt=0,
    flip1stGWAS_signal=0,
    sep_chr_grp=1,
    fig_width=1200,
    fig_height=600,
    angle4xaxis_label=90,
    xgrp_y_pos=0,
    yoffset_setting=%str(offset=(30,0.5)) 
 );


*Alternative codes without using macro;
proc sql;
create table ThreeGWASs_Sub as
select a.*,b.grp,b.rsid as tag_snp
from D.tops as b
left join 
D.ThreeGWASs as a
on a.chr=b.chr and (a.pos between b.pos - 5e5 and b.pos+5e5);

data ThreeGWASs_Sub_hosp ThreeGWASs_Sub_nonhosp;
set ThreeGWASs_Sub;
if grp="Hosp" then output ThreeGWASs_Sub_hosp;
else output ThreeGWASs_Sub_nonhosp;
run;

%Manhattan4DiffGWASs(
dsdin=ThreeGWASs_Sub_nonhosp,
pos_var=pos,
chr_var=tag_snp,
P_var=gwas1_P,
Other_P_vars=gwas2_P pval p, 
logP=1,
gwas_thrsd=7.3,
thrsd_line_color=gray,
dotsize=0.5,
_logP_topval=30, 
y_axix_step=5,
fig_width=1200,
fig_height=800,
fontsize=2,
flip1stGWAS_signal=0,
refline_color_4zero=gray, 
rm_signals_with_logP_lt=0.5,
use_uniq_colors=1, 
uniq_colors=,
gwas_sortedby_numchrpos=0,
outputfigname=Manhattan4three,
angle4xaxis_label=45,
Use_scaled_pos=1,
sep_chr_grp=0
);

*/

/*Example 2;

%Import_Space_Separated_File(abs_filename=E:\LongCOVID_HGI_GWAS\CombineLongCOVIDGWAS\CombineLongCOVIDGWAS.txt,
                             firstobs=1,
							 getnames=yes,
                             outdsd=Assoc);

proc import datafile="E:\LongCOVID_HGI_GWAS\CombineLongCOVIDGWAS\CombineLongCOVIDGWAS.txt"
dbms=tab out=Assoc replace;
getnames=yes;
run;

data Assoc1;
set Assoc;
*if _n_<10000;
rename _chrom=chr;
run;
proc sort data=Assoc1;
by chr pos;
run;
data Assoc1;
set Assoc1;
P=10**(-neg_log_pvalue4W2);
P1=10**(-neg_log_pvalue4W1);
P2=10**(-neg_log_pvalue4N2);
run;
*%debug_macro;
%Manhattan4DiffGWASs(
dsdin=Assoc1,
pos_var=pos,
chr_var=chr,
P_var=P,
Other_P_vars=P1 P2,
logP=1,
gwas_thrsd=7.3,
dotsize=2,
_logP_topval=10
);

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


