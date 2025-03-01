%macro tabulate4cutoff(
dsd,
byids,
target_var,
target_cutoffs,
step,
dsdout,
ge_or_le,
draw_fig4passed_tot=0, /*draw scatter plot with its y-axis for the total number of samples passed the target_cutoffs;
otherwise, it will draw the figure using the % of samples passed the target_cutoffs*/
sumary_fig_ht=1000,
sumary_fig_wt=800,
numcolumns4fig=3
);
*Note: byids will be used to counts how many of them pass the target_cutoffs;

%put Your provided target_var is &target_var;
%put Make sure it is correct! Otherwise the summary statistics will be wrong!;

%put System notes were depressed, but the program is running!;
/*options nonotes;*/
%if %sysfunc(prxmatch(/-/,&target_cutoffs)) %then %do;
 %if &step= %then %do;
  %let target_cutoffs=%range2consecutive_num(arg=&target_cutoffs,step=1);
 %end;
 %else %do;
  %let target_cutoffs=%range2consecutive_num(arg=&target_cutoffs,step=&step);
 %end;
%end;

%let ncutoffs=%numargs(&target_cutoffs);
%put &ncutoffs;

%let nbyids=%numargs(&byids);
/*change byids for proc sql;*/
%let _byids_=%sysfunc(prxchange(s/\s+/%str(,)/,-1,&byids));
/*make empty variable table*/
data byids;
set &dsd;
keep &byids;
proc sort data=byids nodupkeys;by &byids;run;
data byids;
set byids;
do i=1 to &ncutoffs;
 do cutoff_g=0 to 1;
 cutoff_threshold=scan("&target_cutoffs",i,' ')-0;
 output;
 end;
end;
drop i;
run;


%let i=1;
%do %while (%scan(&target_cutoffs,&i,%str(' ')) ne );
 %let cutoff=%scan(&target_cutoffs,&i,%str(' '));
  %put &cutoff;
  data tmp;
  set &dsd;
  %if &ge_or_le=1 %then %do;
  if &target_var>=&cutoff then cutoff_g=1;
  %end;
  %else %do;
  if &target_var<=&cutoff then cutoff_g=1;
  %end;
  else cutoff_g=0;
  run;

  proc sql;
  create table ZX&i as
  select count(*) as total_n,cutoff_g,&_byids_
  from tmp 
  group by cutoff_g,&_byids_
  ;
  data ZX&i;
  set ZX&i;
  cutoff_threshold=&cutoff;
  run;

 %let i=%eval(&i+1);
%end;
data dsdout;
set ZX:;
run;

%let byid_condition=a.%scan(&byids,1,%str(' ')) = b.%scan(&byids,1,%str(' '));
%if &nbyids>=2 %then %do;
 %do i=2 %to &nbyids;
   %let byid=%scan(&byids,&i,%str(' '));
   %let byid_condition=&byid_condition and a.&byid=b.&byid;
 %end;
%end;
/*%put &byid_condition;*/

proc sql;
create table &dsdout as
select a.*,b.total_n 
from byids as a
left join
dsdout as b
on a.cutoff_g=b.cutoff_g and a.cutoff_threshold=b.cutoff_threshold and
   &byid_condition
order by cutoff_g,cutoff_threshold,&_byids_
;

proc datasets lib=work noprint;
delete ZX: byids tmp dsdout;
run;
/*options notes;*/

*Further transpose the output for visualization;
%long2wide4multigrpsSameTypeVars( 
long_dsd=&dsdout, 
outwide_dsd=&dsdout._trans, 
grp_vars=&byids cutoff_threshold, 
subgrpvar4wideheader=cutoff_g, 
dlm4subgrpvar=., 
ithelement4subgrpvar=1, 
SameTypeVars=_numeric_, 
debug=0 
); 


data all_trans; 
set &dsdout._trans; 
if total_n_1=. then total_n_1=0; 
Passed_pct=100*total_n_1/(total_n_1+total_n_0); 
*Also keep the the total number of obs passed the the input cutoff;
Passed_n=total_n_1;
run; 

%let y_var=Passed_pct;
%if &draw_fig4passed_tot=1 %then %let y_var=Passed_n;

*Reset all previous titles; 
title;
 
ods graphics on/reset=all height=&sumary_fig_ht width=&sumary_fig_wt; 

proc sgpanel data=all_trans noautolegend; 

panelby %scan(&byids,1,%str( ))/columns=&numcolumns4fig 
novarname onepanel skipemptycells; 

scatter x=cutoff_threshold y=&y_var/
   name='linename'	markerattrs=(size=15 color=darkred symbol=circlefilled)
%if %numargs(&byids)>1 %then group=%scan(&byids,2,%str( ));
; 
series x=cutoff_threshold y=&y_var/lineattrs=(pattern=dash color=black)

%if %numargs(&byids)>1 %then group=%scan(&byids,2,%str( ));
; 
/*keylegend "linename";*/
label cutoff_threshold="Cutoff threshold" 

%if &draw_fig4passed_tot=1 %then %do;
 &y_var="# of records passed the threshold";
%end;
%else %do;
 &y_var="% of records passed the threshold";
%end;

; 

run; 


%mend;
/*Demo codes:;

*Demo code 1 for SNP AAF analysis;

options mprint mlogic symbolgen;
*pay attention to byids, which will be used to sort the final dataset;
*the order of variables for byids will affect the output order;
%tabulate4cutoff(dsd=SNPs,byids=memname g,target_var=delta,target_cutoffs=10 20 30 40 50 60 70 80 90,step=,dsdout=all,ge_or_le=1);


*Demo code 2 for count data;
 proc freq data=celltype_level_dsd1 noprint;
 table subj*celltype/crosslist out=test;
 run;
*Test how many celltypes passed the count cutoff across subj;
%tabulate4cutoff(
dsd=test,
byids=subj,
target_var=count,
target_cutoffs=0-3000,
step=100,
dsdout=all,
ge_or_le=1
);
*Test how many subj passed the count cutoff across celltypes;
%tabulate4cutoff(
dsd=test,
byids=celltype,
target_var=count,
target_cutoffs=0-3000,
step=100,
dsdout=all,
ge_or_le=1
);


*Demo codes 3 for single cell ASE analysis;

%tabulate4cutoff(dsd=qced,byids=ID celltype,target_var=COV,target_cutoffs=5-100,step=5,dsdout=all,ge_or_le=1);
 %long2wide4multigrpsSameTypeVars( 
long_dsd=all, 
outwide_dsd=all_trans, 
grp_vars=ID celltype cutoff_threshold,
subgrpvar4wideheader=cutoff_g,
dlm4subgrpvar=.,
ithelement4subgrpvar=1,
SameTypeVars=_numeric_, 
debug=0 
); 
data all_trans;
set all_trans;
if n_1=. then n_1=0;
Passed_pct=100*n_1/(n_1+n_0);
run;

title '';
ods graphics on/reset=all height=1600 width=2000;
proc sgpanel data=all_trans;
panelby ID/columns=6 novarname onepanel skipemptycells;
scatter x=cutoff_threshold y=Passed_pct/group=celltype;
series x=cutoff_threshold y=Passed_pct/group=celltype;
label  cutoff_threshold="Coverage threshold" 
          Passed_pct="% of genes with coverage >threshold";
run;

*Select high quality celltypes;
proc sql;
create table good_celltypes as
select distinct celltype, ID
from 	all_trans
where Passed_pct>50 and cutoff_threshold=10;
create table all_trans_qced as
select a.*
from all_trans as a,
         good_celltypes as b
where a.ID=b.ID and a.celltype=b.celltype;

title '';
ods graphics on/reset=all height=800 width=2000;
proc sgpanel data=all_trans_qced;
panelby ID/columns=6 novarname onepanel skipemptycells;
scatter x=cutoff_threshold y=Passed_pct/group=celltype;
series x=cutoff_threshold y=Passed_pct/group=celltype;
label  cutoff_threshold="Coverage threshold" 
          Passed_pct="% of genes with coverage >threshold";
run;

*/
