%macro Adj_missing_cell_value4fisher(
/*This macro will add value of 1 to the 2x2 contigency table derived from the input long format dsd*/
longformdsd=,/*long format dsd containing >=3 columns: group var and pheno var, as well as a by variables*/
grp_var=grp,/*grp var for proc freq grp*pheno*/
pheno_var=new_pheno,/*pheno var for proc freq grp*pheno*/
by_vars=by_vars,/*one or multiple variables to stratify the adjustment for the first 
two variables, including grp_var and pheno_var*/
newdsdout=new_dsd /*Modified 2x2 contigency dsd for combined by_vars with missing cells added 
with value of 1 and all other 3 cells added with value of 1, which enable the calculation of OR, 
and the dsd can be calculated for OR with the option "weight count" in the proc freq procedure;*/
);

%if %length(&by_vars)>0 %then %do;
  proc sort data=&longformdsd;
  by &by_vars &grp_var &pheno_var;
  run;
%end;

proc freq data=&longformdsd noprint;
table &grp_var*&pheno_var/list out=frq_list;
by &by_vars;
run;

proc freq data=&longformdsd nlevels noprint;
table &by_vars /noprint out=by_var_levels;
run;
data by_var_levels(drop=count percent);
set by_var_levels;
level_n=catx("_","by_vars_grp",trim(left(put(_n_,best12.))));
run;

*Add these level_n into the input data set;
proc sql;
create table longformatdsd as
select *
from &longformdsd
natural left outer join
by_var_levels 
;
create table frq_list as 
select *
from frq_list 
natural left outer join by_var_levels;

*Create a macro variable to hold these by_var_levels;
proc sql noprint;
select level_n into: by_var_levels separated by ' '
from by_var_levels;
select put(count(*),best12.) into: tot_by_var_levels 
from by_var_levels;


%do bi=1 %to &tot_by_var_levels;
data &newdsdout._&bi;
set longformatdsd;
where level_n="%scan(&by_var_levels,&bi,%str( ))";
run;

proc sql noprint;
select count(*) as ncells into: tot_ncells
     from frq_list (where=(level_n="%scan(&by_var_levels,&bi,%str( ))"));
%if &tot_ncells < 3 %then %do;
   %put &bi;
   %put &tot_ncells;
   %abort 255;
%end;     
*Note: the use of longformatdsd but not &newdsdout._&bi guarantee all 4 cells can be captured;
proc sql;
create table &newdsdout._&bi as
select "%scan(&by_var_levels,&bi,%str( ))" as level_n, n1.*,n2.ncells from 
(select a.*,b.count
from 
(select a1.&grp_var,b1.&pheno_var
from (select distinct &grp_var from longformatdsd) as a1,
     (select distinct &pheno_var from longformatdsd) as b1
 ) as a
 left join
 frq_list (where=(level_n="%scan(&by_var_levels,&bi,%str( ))")) as b
 on a.&grp_var=b.&grp_var and a.&pheno_var=b.&pheno_var) as n1,
 (select count(*) as ncells
     from frq_list (where=(level_n="%scan(&by_var_levels,&bi,%str( ))"))) as n2
 order by &grp_var desc,&pheno_var asc;

 data &newdsdout._&bi;
 set &newdsdout._&bi;

 if ncells^=4 then adj_count=ifc(count>0,count,0)+1;
 else adj_count=count;
 
 run;
 
 %end;
 
 *Note: this procedure is prone to errors as it may truncate variable lengths;
 *leading to the failure in downstream merging using natural left outer join based on common variables;
 /*
 data &newdsdout;
 set &newdsdout._:;
 run;
 */
 *To address the above potential issues, let us use the following macro;
 %Union_Data_In_Lib_Rgx(lib=work,excluded=XXXXXX,dsd_contain_rgx=&newdsdout._,dsdout=&newdsdout);
 data &newdsdout;set &newdsdout;drop dsd;run;
 
 proc sql;
 create table &newdsdout as
 select *
 from &newdsdout as x1
 natural left outer join
 (select distinct * from 
   frq_list(drop=count percent &grp_var &pheno_var)
    ) as x2;
/*  %abort 255; */
 proc datasets nolist;
 delete frq_list &newdsdout._: longformdsd by_var_levels;
 run;
 
%mend;

/*Demo codes:;

data a;
length grp $8.;
input grp :$8. new_pheno $;
if grp="a" then grp="Case";
else grp="Other";
by_var="AAAAAA";
if _n_>30 then by_var="B";
cards;
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 0
a 1
b 0
b 0
a 0
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 1
a 0
a 1
b 0
b 0
a 0
a 1
;
*Note that if one of the cell for the 2x2 contigency table is with 0 count, there will be no OR output;
*Here, designating missing value "." for all "b 1" will lead to no OR output;
proc freq data=a order=data;
table grp*new_pheno/measures relrisk OR fisher exact;
run;
proc freq data=a nlevels noprint;
table by_var /noprint out=by_var_levels;
run;

%Adj_missing_cell_value4fisher(
longformdsd=a,
grp_var=grp,
by_vars=by_var,
pheno_var=new_pheno,
newdsdout=new_dsd
);

*Note: order by data for proc freq ensures the group 'Other' and pheno group 0 used as reference for OR calculation;
*Testing the sort by descending or ascending indeed affects the OR calculation direction;
*The 1st pheno grp is used as reference;
proc sort data=new_dsd;by by_var descending grp new_pheno;
run;
ods trac on;
ods output FishersExact=FishersExact
           CrossTabFreqs=CrossTabFreqs
           Measures=Measures
           RelativeRisks=RelativeRisks;
proc freq data=new_dsd order=data;
table grp*new_pheno/measures relrisk OR fisher exact ;
weight adj_count;
by by_var;
run;
ods trace off;

*/


