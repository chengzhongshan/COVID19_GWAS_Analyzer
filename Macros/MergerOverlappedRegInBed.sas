%macro MergerOverlappedRegInBed(bedin,chr_var,st_var,end_var,bedout);
proc sql;
create table zzz as
select a.*,
       b.&chr_var as b_&chr_var, b.&st_var as b_&st_var, b.&end_var as b_&end_var
from &bedin as a
left join 
&bedin as b
on ((a.&chr_var=b.&chr_var and a.&st_var^=b.&st_var) and (a.&st_var between b.&st_var and b.&end_var));

create table zzz1 as
select *
from zzz
where catx(':',&chr_var,&st_var) not in 
(
 select catx(':',b_&chr_var,b_&st_var)
   from zzz
   where b_&st_var^=.
)
;

proc sort data=zzz1;by &chr_var &st_var b_&st_var;
data zzz1_min(drop=b_&end_var);
set zzz1;
if first.&st_var then output;
by &chr_var &st_var b_&st_var;

proc sort data=zzz1;by &chr_var &st_var b_&end_var;
data zzz1_max;
set zzz1;
if last.&st_var then output;
by &chr_var &st_var b_&end_var;

proc sql;
create table zzz_min_max as
select a.*,b.b_&end_var
from zzz1_min as a
left join 
zzz1_max as b
on a.&chr_var=b.&chr_var and 
   a.&st_var=b.&st_var;

data zzz2;
set zzz_min_max;
if &st_var>b_&st_var and b_&st_var^=. then &st_var=b_&st_var;
if &end_var<b_&end_var then &end_var=b_&end_var;

data &bedout(drop=b_&chr_var b_&st_var b_&end_var);
set zzz2;

proc sort data=&bedout nodupkeys; by &chr_var &st_var &end_var;
run;

%mend;
/*
%MergerOverlappedRegInBed(bedin=bed
                         ,chr_var=var1
                         ,st_var=var2
                         ,end_var=var3
                         ,bedout=xyz);
*/
