%macro IdentifyBedClusters(bedin,chr_var,st_var,end_var,bedout,dist=0);

/*Note: the input bed should have regions with st < end position and from
the same or different chrs or groups!*/

/*Try to lookup the st pos of each bed region with other regions in the same bed*/
/*the a.&st_var^=b.&st_var is important to exclude the matching with itself*/
/*Also, the a.&st_var between (b.&st_var-1) and (b.&end_var+1) will make an offset
of 1 in the looking up, thus it is possible to extend the distance for matching
by increase the distance of 1 to other number! A default macro var &dist is assigned
with 0.*/

/*Add distance to each st and end position*/
 data bedadddist(keep=&chr_var &st_var &end_var);
 set &bedin;
%if &dist gt 1 %then %do;
 &st_var=&st_var-&dist;
 /*reset the st as 0 when it is negative*/
/* if &st_var<0 then &st_var=0;*/
 /*Keeping negative value can be used to get back the original pos*/
 &end_var=&end_var+&dist;
%end;
 run;

 /*Important to remove duplicate records*/
 proc sort data=bedadddist nodupkeys;by _all_;run;

/*This step is the most important part, which include the concept of
how to merge bed regions:
(a.&chr_var=b.&chr_var and a.&st_var=b.&st_var and a.&end_var^=b.&end_var) or
((a.&chr_var=b.&chr_var and a.&st_var^=b.&st_var) and 
(a.&st_var between (b.&st_var-1) and (b.&end_var+1)))


scenario 1: all regions are overlapped!

a: 1 30 |--------|
b: 10 50    |----------|
c: 5  40   |--------|
if the st pos of a region is included in any other regions, it
indicates that the region is overlapped with other regions;
When combining all regions in long format and using proc sql
to lookup based on the conditions of a.st between b.st and b.end,
and a.st is ne b.st, this will exclude its match with itself!
This will result in a table as follows:
a.st a.end b.st b.end
1    30    .	.
10   50    1    30
10   50    5    40
5    40    1    30

Here all bed regions on the left part of the table appeared in the 
right part of the table, so all of them will be excluded;
thus we will rescue this by get the minimum st among a.st and b.st,
and maximum end among a.end and b.end;

scenario 2: some regions are overlapped
a: 1 30 |--------|
b: 10 50    |----------|
c: 5  40   |--------|
d: 60 100               |----------|

the lookup table of the dataset with itself is as follows:
a.st a.end b.st b.end
1    30    .    . 
10   50    1    30
10   50    5    40
5    40    1	30
60  100    .    .

So the two records '1 30', '10 50', and '5 40'  will be excluded from the left part
of the table, and it is the same for the matched records between left and righ parts,
only the record '60 100' will be kept; by keeping the excluded records and get the 
minimum st and maximum end position among these excluded records, we can rescue it,
and finally we can combine it with the record '60 100';

scenario 3: this is the easiest situation to adress;
a: 1 30 |--------|
b: 10 50    |----------|
d: 60 100               |----------|

The lookup table of the dataset with itself is as follows:
a.st a.end b.st b.end
1    30    .    .
10   50    1    30
60  100    .    .

As scenario 2, the record '1 30' will be excluded from the left part of the table;
the matched record will be merged as '1 50', and '60 100' will be kept,too! 

*/

proc sql;
create table zzz as
select a.*,
       b.&chr_var as b_&chr_var, b.&st_var as b_&st_var, b.&end_var as b_&end_var
from bedadddist as a
left join 
bedadddist as b
on ( (a.&chr_var=b.&chr_var and a.&st_var=b.&st_var and a.&end_var^=b.&end_var) or
   ((a.&chr_var=b.&chr_var and a.&st_var^=b.&st_var) and
   (a.&st_var between (b.&st_var-1) and (b.&end_var+1)))
);

/*need to sort the data for the correct labeling misstag*/
proc sort data=zzz;by &chr_var &st_var;

/*use missing value as a marker to label different clusters*/
data zzz;
set zzz;
/*add a missing tag to count how many separated clusters*/
retain misstag 0;
if b_&st_var=. then misstag=misstag+1;
run;

proc sql;
create table &bedout as 
select min(&st_var) as &st_var,min(b_&st_var) as b_&st_var,
       max(&end_var) as &end_var,max(b_&end_var) as b_&end_var,
	   &chr_var,misstag as cluster
from zzz 
group by &chr_var, misstag;

/*Get final minimum st and max end positions for each &chr_var*/
data &bedout(keep=&chr_var &st_var &end_var cluster);
set &bedout;
if (&st_var>b_&st_var and b_&st_var^=.) then &st_var=b_&st_var;
if (&end_var<b_&end_var) then &end_var=b_&end_var;
run;

proc sql;
create table &bedout(drop=b: misstag) as 
select a.*,
       b.&chr_var as cluster_chr,
	   b.&st_var as cluster_st,
	   b.&end_var as cluster_end,
	   b.cluster
from (
select distinct &chr_var,&st_var,&end_var,misstag
from
zzz
) as a
left join
&bedout as b
on a.misstag=b.cluster and a.&chr_var=b.&chr_var
order by a.&chr_var,a.&st_var,a.&end_var;

create table &bedout as
select a.*,count(*) as NumBedMergedInCluster
from &bedout as a
group by cluster
order by a.&chr_var,a.&st_var,a.&end_var;
quit;
/*get back the original pos*/
%if &dist>0 %then %do;
 data &bedout;
 set &bedout;
 &st_var=&st_var+&dist;
 &end_var=&end_var-&dist;
 if cluster_st<0 then cluster_st=0;
 run;
%end;

/*Add these clusters into the original table*/
proc sql;
create table &bedout as 
select a.*,b.cluster_chr,
b.cluster_st,b.cluster_end,
b.NumBedMergedInCluster,b.cluster
from &bedin as a,
     &bedout as b
where a.&chr_var=b.&chr_var and a.&st_var=b.&st_var and
      a.&end_var=b.&end_var
order by cluster,cluster_chr,cluster_st,cluster_end;

%mend;

/*
data bed;
input var1 $ var2 var3;
cards;
b 1 30
b 1 30
b 40 100
b 30 2000
b 5000 5400
b 5300 5500
b 6000 8000
a 1 30
a 10 50
a 5 40
a 60 100
;

options mlogic mprint symbolgen;
%IdentifyBedClusters(bedin=bed
                         ,chr_var=var1
                         ,st_var=var2
                         ,end_var=var3
                         ,bedout=xyz);
proc print;run;
%IdentifyBedClusters(bedin=bed
                         ,chr_var=var1
                         ,st_var=var2
                         ,end_var=var3
                         ,bedout=xyz
                         ,dist=5);
proc print;run;
*/

/*
data bed1;
input var1 $ var2 var3;
cards;
a 1 30
a 10 50
a 5 40
a 60 100
;

%IdentifyBedClusters(bedin=bed1
                         ,chr_var=var1
                         ,st_var=var2
                         ,end_var=var3
                         ,bedout=xyz
                         ,dist=0);
proc print;run;
*/

