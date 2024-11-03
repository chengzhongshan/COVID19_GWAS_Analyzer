%macro adjust_close_positions(
/*Limitation: where there are only 2 closely related positions, a fixed distance with Pct4OnlyTwoPos*step will be used to separate them*/
indsd=,
outdsd=,
pos_var=pos,
new_pos_var=newpos,
dist_pct_to_cluster_pos=0.01,/*Use the pct of range of positions to cluster these positions
Note: positions with distance less then ceil(&dist_pct_to_cluster_pos*(max(&pos_var)-min(&pos_var)+1)) will
be asigned into a single cluster for further adjusting distance using amplification_fc!*/
amplificaiton_fc=1.5, /*Increase the distance fold change among among these close records*/
make_even_pos=1, /*If provide value 1, which will ensure all position with the same distance between min and max pos;
This will replace previous setting of dist_pct_to_cluster_pos and amplificaiton_fc;
Note: *Only when the total number of records is gt the number of distant cluster, the macro will generate even positions for all records
*/
Pct4OnlyTwoPos=0.5,/*In case of only two positions, it is necessary to use arbitrary proportion of dist_step to separate them,
i.e., minus and add Pct4OnlyTwoPos*dist_step and for the first and second positions, respectively*/
fixed_min_pos=,/*Provide fixed minimum and maximum positions for generating even psotions;
Default is empty to use the minimum and maximum positions from input dsd!*/
fixed_max_pos=
);
proc sql noprint;
select count(unique(&pos_var)) into: tot_rows
from &indsd;

select min(&pos_var),max(&pos_var),ceil(&dist_pct_to_cluster_pos*(max(&pos_var)-min(&pos_var)+1)),
min(&pos_var),max(&pos_var), (max(&pos_var)-min(&pos_var)+1)/(1+&tot_rows)
into: 
min_pos,:max_pos,:offset_dist,:min_pos,:max_pos,:dist_step
from &indsd;
quit;

%if %length(&fixed_min_pos)>0 %then %let min_pos=&fixed_min_pos;
%if %length(&fixed_max_pos)>0 %then %let  max_pos=&fixed_max_pos;
%let dist_step=%sysevalf((&max_pos-&min_pos+1)/(1+&tot_rows));

proc sort data=&indsd out=&outdsd nodupkeys;by &pos_var;run;
/* proc print;run; */


data &outdsd(drop=_pre_pos_);
retain _pre_pos_ dist_cluster 0;
set &outdsd;
ord=_n_;
if _n_=1 then do;
   dist_cluster=1;
   _pre_pos_=&pos_var;
   output;
end;
if _n_>1 and &pos_var-_pre_pos_<&offset_dist then do;
    _pre_pos_=&pos_var;
    dist_cluster=dist_cluster;
    output;
 end;
 else if _n_>1 then do;
    _pre_pos_=&pos_var;
    dist_cluster=dist_cluster+1;
    output;
 end;
run;
/* proc print;run; */


/* %let amplificaiton_fc=1.5; */
proc sql;
create table &outdsd._with_close_records as
select dist_cluster,&pos_var,ord,pos+(&pos_var-avg(&pos_var))*&amplificaiton_fc as _pos_
from &outdsd
group by dist_cluster
having count(dist_cluster)>1
order by ord;

proc sql;
create table &outdsd as
select *
from &outdsd
natural full join
&outdsd._with_close_records
;
*This will keep duplicate records in the outdsd;
proc sql;
create table &outdsd as
select *
from &indsd
natural full join
&outdsd;


proc sort data=&outdsd;by ord;
proc sql noprint;
select max(dist_cluster) into: max_cluster
from &outdsd;

data &outdsd(rename=(_pos_=&new_pos_var) );
set &outdsd;
if _pos_=. then _pos_=&pos_var;
/*drop=dist_cluster ord;*/
run;

*Only when the total number of records is gt the number of distant cluster, the macro will generate even positions for all records;
%if &make_even_pos=1 and  &max_cluster^=&tot_rows %then %do;
data &outdsd;
set &outdsd;
&new_pos_var=&min_pos+ord*&dist_step;
run;
%end;


proc sql;
drop table &outdsd._with_close_records;
quit;
/* proc print;run; */

*The above will failed to revise the positions of markers if the total number of which is 2;
*The following code will update these positions specifically for the above scienario;
proc sql noprint;
select count(*) into: _tot_rescaled_pos_
from &outdsd;
%if &_tot_rescaled_pos_=2 %then %do;
data &outdsd;
set &outdsd;
if _n_=1 then do;
/*  &new_pos_var=&new_pos_var-0.1*&dist_step;*/
  &new_pos_var=&new_pos_var-&Pct4OnlyTwoPos*&dist_step;
end;
else do;
/*  &new_pos_var=&new_pos_var+0.1*&dist_step;*/
  &new_pos_var=&new_pos_var+&Pct4OnlyTwoPos*&dist_step;
end;
run;
%end;

%mend;

/*Demo codes:
data AAA;
input pos;
cards;
10
10
13
14
100
200
500
502
405
1000
;

%adjust_close_positions(
indsd=AAA,
outdsd=BBB,
pos_var=pos,
new_pos_var=newpos,
dist_pct_to_cluster_pos=0.01,
amplificaiton_fc=1.5,
make_even_pos=1, 
fixed_min_pos=1,
fixed_max_pos=1500
);

*/






