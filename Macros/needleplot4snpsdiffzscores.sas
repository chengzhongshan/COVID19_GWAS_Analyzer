%macro needleplot4snpsdiffzscores(
diffzscore_gwas,
gwas1_z,
gwas2_z,
snp_var,
snps,
diffzscore_p_var,
gwas1pvar,
gwas2pvar,
fig_height=400,
fig_width=600,
NotDrawBubbleBySize=0, /*Draw common bubble plot with the same size of bubbles*/
transparency4needles=0.6,
keep_snp_order4xaxis=0,
draw_p_axis_by_z_direction=1, /*Draw the log10P value axis on the end-right by +/- direction of its corresponding z-scores*/
bubble_transparency=0.1,
xaxisfontsize=10,
maxbublesize=10 /*restricted the largest size for -log10P in pixel*/
);
%let snps=%sysfunc(prxchange(s/%str(%")//,-1,&snps));
data a;
length grp $8.;
set &diffzscore_gwas;
if &gwas1_z * &gwas2_z>0 then grp='Same';
else grp='Opposite';
where &snp_var in (%quotelst(&snps));
run;
proc print;run;
/*sort the dataset by gwas2_z*/
proc sort data=a;by &gwas2_z;
data b;
set a(keep=&diffzscore_p_var &snp_var &gwas1_z &gwas2_z grp
      %if &gwas1pvar ne %then &gwas1pvar ;
      %if &gwas2pvar ne %then &gwas2pvar ;);
array _z_{2} &gwas1_z &gwas2_z;
do i=1 to 2;
   g="gwas"||put(i,z1.);
   z=_z_{i};
   gwas=vname(_z_{i})||&snp_var;
   /*Only keep one copy of diffzscore_p*/
   if i=1 then do;
       diffzscore_p=-log10(&diffzscore_p_var);
      %if &gwas1pvar ne %then %do;
        gwas1p=-log10(&gwas1pvar);
        %if &draw_p_axis_by_z_direction=1 %then %do;
          *asign negative log10P value if gwas_zscore<0;
          if &gwas1_z<0 then gwas1p=-1*gwas1p;
        %end;
      %end;
       %if &gwas2pvar ne %then %do;
        gwas2p=-log10(&gwas2pvar);
        %if &draw_p_axis_by_z_direction=1 %then %do;
          *asign negative log10P value if gwas_zscore<0;
          if &gwas2_z<0 then gwas2p=-1*gwas2p;
         %end;
       %end;
   end;
   else do;
       diffzscore_p=.;
       %if &gwas1pvar ne %then %do;
       gwas1p=.;
       %end;
       %if &gwas2pvar ne %then %do;
       gwas2p=.;
       %end;
   end;
   n=_n_;
   output;
end;
drop &gwas1_z &gwas2_z;
run;

/* ods graphics/width=800px height=400px; */
/* proc sgpanel data=b noautolegend; */
/* panelby chr/border columns=3; */
/* needle x=pos y=z/baseline=0 baselineattrs=(pattern=dash color=darkred) group=i lineattrs=(thickness=5); */
/* colaxis min=1 type=log logbase=10 logstyle=logexponent; */
/* run; */

proc sort data=b out=x nodupkeys;by n;run;
proc sql noprint;
select quote(compress(&snp_var)) into: names separated by ' '
from x 
order by n;
;

select quote(strip(left(put(n,2.)))) into: num_xaxis separated by ' '
from x
order by n;

select max(n) into: tot
from x;
/* options mprint mlogic symbolgen; */
/* proc print data=b;run; */

*Reduce diffzscore_p value to below 3;
proc sql noprint;
select max(diffzscore_p) into: max_assoc_p
from b;

*Fix a bug when the bubble size is not proprotional to log10P;
*Mainly due to the the bubble size is automatically adjusted for each group of GWAS;
*This is an isues, when the ratio between min and max of log10P are hug but the real;
*log10P is not very large, which will result in large bubble for the max log10P;
*though the max log10P is not very large!;
data b;
set b;
%if %sysevalf(&max_assoc_p>5) or &NotDrawBubbleBySize=1 %then %do;
%*Ensure all log10P with the same bubble size;
bubblesize=1;
run;
%end;
%else %do;
*This will not run, only if we want to draw bubble by diffzscore_p;
*Note: all bubble plots for different GWAS will be drawed based on the size of diffzacore_p!;
bubblesize=diffzscore_p;
%end;
run;

*Decide whether to sort xaxis by the input order of snps;
%if &keep_snp_order4xaxis=1 %then %do;
%rank4grps(
     grps=&snps,
     dsdout=snps_rank
);
proc sql;
create table b as
select a1.*,a2.num_grps
from b as a1
left join
snps_rank as a2
on a1.&snp_var=a2.grps;
data b;
set b;
n=num_grps;
run;
*Need to sort the data again by n and g;
proc sort data=b;by n g;run;
*use updated macro var names;
%let names=%quotelst(&snps);
%end;



/* *make order for the var gwas based on user input order;    */
/* %mkfmt4grps_by_var( */
/*     grpdsd=snps_rank, */
/*     grp_var=grps, */
/*     by_var=num_grps, */
/*     outfmt4numgrps=snp_grps2nums, */
/*     outfmt4chargrps=nums2snp_grps */
/* ); */
/*  */
/* *combine all gwas sub data sets; */
/* data b; */
/* set b; */
/* new_num_grps=input(grps,snp_grps2nums.); */
/* run; */


ods graphics on /reset=all noborder height=&fig_height.px width=&fig_width.px;
proc sgplot data=b;
needle x=n y=z/baseline=0 baselineattrs=(pattern=dash color=darkred) 
               group=g  lineattrs=(thickness=30) name="ndl" transparency=&transparency4needles;
series x=n y=diffzscore_p/y2axis lineattrs=(pattern=dash color=lightred)
                    transparency=0 name="sr";  
bubble x=n y=diffzscore_p size=bubblesize/colormodel=(darkorange) bradiusmax=&maxbublesize
                               y2axis fill fillattrs=(color=lightred) transparency=&bubble_transparency
                               name="bub";  
%if &gwas1pvar ne %then %do;                               
bubble x=n y=gwas1p size=bubblesize/colormodel=(darkorange) bradiusmax=&maxbublesize
                               y2axis fill fillattrs=(color=lightgreen) transparency=&bubble_transparency
                               name="bub1"; 
series x=n y=gwas1p/y2axis lineattrs=(pattern=dash color=lightgreen)
                    transparency=0 name="sr1";                                 
%end;  
%if &gwas1pvar ne %then %do;                             
bubble x=n y=gwas2p size=bubblesize/colormodel=(darkorange)  bradiusmax=&maxbublesize
                               y2axis fill fillattrs=(color=lightblue) transparency=&bubble_transparency
                               name="bub2"; 
series x=n y=gwas2p/y2axis lineattrs=(pattern=dash color=lightblue)
                    transparency=0 name="sr2";                                 
%end;                               
xaxis values=(1 to &tot by 1) valuesdisplay=(&names) 
      valuesrotate=diagonal fitpolicy=thin 
      valueattrs=(size=&xaxisfontsize family=bold) label="";
x2axis label="";
yaxis label="Association z-score";

%if &draw_p_axis_by_z_direction=0 %then %do;
y2axis min=0 label='-log10(P)'
%end;
%else %do;
y2axis label='-log10(P)';
%end;


discretelegend "ndl" "bub" "bub1" "bub2"/ title="";
*Remove the xaxis label of var n;
label n="SNP";
run;
%mend;

/*Demo:

*libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
libname D '/home/cheng.zhong.shan/data';
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;


%needleplot4snpsdiffzscores(
diffzscore_gwas=D.hgi_b1_vs_b2,
gwas1_z=gwas1_z,
gwas2_z=gwas2_z,
snp_var=rsid,
snps=rs11896844 rs73007494 rs76569177 rs73007488 rs11904446 rs7558266 rs72976117 rs75379044 rs16831827,
diffzscore_p_var=pval,
gwas1pvar=gwas1_p,
gwas2pvar=gwas2_p,
fig_height=400,
fig_width=600,
NotDrawBubbleBySize=0,
transparency4needles=0.2,
keep_snp_order4xaxis=0,
draw_p_axis_by_z_direction=1
);

*/

