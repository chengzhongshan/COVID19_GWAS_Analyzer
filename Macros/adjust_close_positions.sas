%macro adjust_close_positions(
/*Limitation: where there are only 2 closely related positions, a fixed distance with Pct4OnlyTwoPos*step will be used to separate them;
Additonally, if there are positions too close to the start or end of position in the figure, it is possible to modify the internal macro
var pct2adj4dencluster from 0.25 to larger value but less than 1 at line 90 in the sas macro!
amplification_fc can be increased to separate closely related positions, too!*/
indsd=,
outdsd=,
pos_var=pos,
new_pos_var=newpos,
dist_pct_to_cluster_pos=0.01,/*Use the pct of range of positions to cluster these positions
Note: positions with distance less then ceil(&dist_pct_to_cluster_pos*(max(&pos_var)-min(&pos_var)+1)) will
be asigned into a single cluster for further adjusting distance using amplification_fc!*/
amplification_fc=1.5, /*Increase the distance fold change among these close records;
Note: all positions within the same cluster will be amplified using the formula: pos+(&pos_var-median(&pos_var))*&amplification_fc by cluster*/
make_even_pos=1, /*If provide value 1, which will ensure all position with the same distance between min and max pos;
This will replace previous setting of dist_pct_to_cluster_pos and amplification_fc;
Note: *Only when the total number of records is gt the number of distant cluster, the macro will generate even positions for all records
*/
pct2adj4dencluster=0.05,/*This parameter is mainly designed when make_even_pos=0; it is useful when elements within a cluster is overlapped with each other
or overlapped with elements from other cluster, so it is feasible to avoid this issue by increasing the pct or reducing it.
However, when make_even_pos=1, the macro will multiple the amplification_fc with 10*pct2adj4dencluster to further enlarge the even distance among positions*/
Pct4OnlyTwoPos=0.5,/*In case of only two positions, it is necessary to use arbitrary proportion of dist_step to separate them,
i.e., minus and add Pct4OnlyTwoPos*dist_step and for the first and second positions, respectively*/
fixed_min_pos=,/*Provide fixed minimum and maximum positions for generating even psotions;
Default is empty to use the minimum and maximum positions from input dsd!*/
fixed_max_pos=
);

proc sql noprint;
select count(unique(&pos_var)) into: tot_rows
from &indsd;

select min(&pos_var),max(&pos_var),
ceil(&dist_pct_to_cluster_pos*(max(&pos_var)-min(&pos_var)+1)),
min(&pos_var), max(&pos_var), 
(max(&pos_var)-min(&pos_var)+1)/(1+&tot_rows)
into: min_pos,:max_pos,
:offset_dist,
:min_pos,:max_pos,
:dist_step
from &indsd;
quit;

%if %length(&fixed_min_pos)>0 %then %let min_pos=&fixed_min_pos;
%if %length(&fixed_max_pos)>0 %then %let  max_pos=&fixed_max_pos;
%let dist_step=%sysevalf((&max_pos-&min_pos+1)/(1+&tot_rows));

*Need to update the macro var offset_dist as min_pos and max_pos might be changed;
%let offset_dist=%sysevalf(&dist_pct_to_cluster_pos*(&max_pos-&min_pos+1));

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
*This means that two positions with distance less than the offset_dist will be assigned with the same cluster number;
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


/* %let amplification_fc=1.5; */
*Note that if these positions within a cluster are too close, the adjusted position by only adding or minusing median(pos) would fail to separate positions;
*So by including the ratio between distance between positions within a cluster to the average positions in the cluster to the offset_dist and further reduce it by 10 fold;
*these positions will be separated from each other;

*Note: that it is necessary to use median pos as a separator to add or substract offset distances among positions within a cluster;
*the function avg fails to separate the most closest positions in each cluster, as these position tend to be not changed in scale in the final output;


*Note that the extra amplification factor 0.1*&offset_dist/abs(&pos_var-median(&pos_var)) is not multiplied for _pos_;
*Instead, we multiple it with the new factor: 10*pct2adj4dencluster; 
proc sql;
create table &outdsd._with_close_records as
select dist_cluster,&pos_var,ord,
&pos_var+(&pos_var-median(&pos_var))*&amplification_fc*(10*&pct2adj4dencluster) as _pos_
from &outdsd
group by dist_cluster
having count(dist_cluster)>1
order by ord;
/*proc print;run;*/
/*%abort 255;*/

*Now update the positions in the output data set;
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
/*proc print;run;*/

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
*The following code will update these positions specifically for the above scenario;
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
/*proc print;run;*/
*Further correct the minimum and maximum value in the outpu data set;
data &outdsd;
set &outdsd;
if &new_pos_var<&min_pos then &new_pos_var=&pos_var-(&max_pos-&min_pos)*0.05;
if &new_pos_var>&max_pos then &new_pos_var=&pos_var+(&max_pos-&min_pos)*0.05;
run;
*Further separate positions that are too close based on the  cutoff 0.1*&dist_step;
data &outdsd(drop=_new_pos_var_);
set &outdsd;
  if &new_pos_var-lag(&new_pos_var)<0.5*&dist_step  then do;
   if first.dist_cluster then do;
     _new_pos_var_=lag(&new_pos_var)+0.5*&dist_step;
   end;
   else do;
	 _new_pos_var_=lag(&new_pos_var)+0.25*&dist_step;
   end;
  end;
  if _new_pos_var_^=.  then &new_pos_var=_new_pos_var_;
  by dist_cluster;
run;
/*proc print;run;*/
/*%abort 255;*/

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
1448
;

%debug_macro;

%adjust_close_positions(
indsd=AAA,
outdsd=BBB,
pos_var=pos,
new_pos_var=newpos,
dist_pct_to_cluster_pos=0.1,
amplification_fc=1.5,
make_even_pos=0, 
fixed_min_pos=1,
fixed_max_pos=1500
);

*/






