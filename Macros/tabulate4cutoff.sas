%macro tabulate4cutoff(dsd,byids,target_var,target_cutoffs,step,dsdout,ge_or_le);
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
  select count(*) as n,cutoff_g,&_byids_
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
select a.*,b.n 
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
%mend;
/*
options mprint mlogic symbolgen;
*pay attention to byids, which will be used to sort the final dataset;
*the order of variables for byids will affect the output order;
%tabulate4cutoff(dsd=SNPs,byids=memname g,target_var=delta,target_cutoffs=10 20 30 40 50 60 70 80 90,step=,dsdout=all,ge_or_le=1);
*/
