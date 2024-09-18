%macro MergerOverlappedRegInBed(
/*Note: the input vars, including chr_var, st_var, and end_var should be numeric;*/
bedin,
chr_var,
st_var,
end_var,
bedout,
add_original_bed=1, /*if value is 1, the output bedout will merge the original bedin with the newly merged bed regions for these input bed regions*/
dist2st=0,/*Reduce or increase the original bed start position by providing negative or positve values in bp*/
dist2end=0 /*Reduce or increase the original bed end position by providing negative or positve values in bp*/
);

%if %length(&dist2st)>0 %then %do;
     data &bedin;
		 set &bedin;
		 Adj_st=&st_var+&dist2st;
		 if Adj_st<0 then Adj_st=0;
		 run;
		 %let st_var=Adj_st;
%end;

%if %length(&dist2st)>0 %then %do;
     data &bedin;
		 set &bedin;
		 Adj_end=&end_var+&dist2end;
		 if Adj_end<0 then Adj_end=0;
		 run;
		 %let end_var=Adj_end;
%end;



*Get the pairwise overlapped regions;
proc sql;
create table zzz as
select a.*,
       b.&chr_var as b_&chr_var, b.&st_var as b_&st_var, b.&end_var as b_&end_var
from &bedin as a
left join 
&bedin as b
on ((a.&chr_var=b.&chr_var and a.&st_var^=b.&st_var) and (a.&st_var between b.&st_var and b.&end_var));

*some regions only overlapped with one other regions may be missing in this step;
*which is required to be rescued later;
data zzz1;
set zzz;
*When the record does not overlap with other regions, let use its own region as the new bed regions;
if b_&st_var=. then do;
			b_&chr_var=&chr_var;
			b_&st_var=&st_var;
			b_&end_var=&end_var;
end;

data zzz1;
set zzz1;

*add the label to tag each records for looking up later;
ord=_n_;

*After adding the ord tag, we can extend the original records by comparing them with these regions overlapped with them;
*Change st position;
if &st_var>b_&st_var then do;
 &st_var=b_&st_var;
end;
else do;
 b_&st_var=&st_var;
end;
*Change end position;
if &end_var<b_&end_var then do;
 &end_var=b_&end_var;
end;
else do;
 b_&end_var=&end_var;
end;
run;

/*%abort 255;*/

*Need to further merge overlapped regions;
proc sql;
create table zzz1 as
select a.*,b.b_&st_var as new_&st_var,b.b_&end_var	as new_&end_var
from zzz1 as a
left join
zzz1 as b
on a.b_&chr_var=b.b_&chr_var and 
(
      (a.b_&st_var between b.b_&st_var and b.b_&end_var) or 
      (a.b_&end_var between b.b_&st_var and b.b_&end_var)
 );

data zzz1;
set zzz1;
if 	b_&st_var > new_&st_var then b_&st_var=new_&st_var;
if b_&end_var < new_&end_var then b_&end_var=new_&end_var;
run;

proc sql;
create table zzz1 as
select a.*, min(b_&st_var) as min_st,max(b_&end_var) as max_end
from zzz1	as a
group by ord;

/*data zzz1 (drop=min_st max_end new_&st_var new_&end_var);*/
/*data zzz1;*/
data zzz1(keep=b_&chr_var b_&st_var b_&end_var rename=(b_&chr_var=&chr_var b_&st_var=&st_var b_&end_var=&end_var));
set zzz1;
b_&st_var=min_st;
b_&end_var=max_end;
proc sort data=zzz1 nodupkeys;by &chr_var &st_var &end_var;
run;

/*%abort 255;*/

data &bedout;
set zzz1;
run;

proc sort data=&bedout nodupkeys; by &chr_var &st_var &end_var;
run;

*lookup original records with the merged bed;
%if &add_original_bed=1 %then %do;
proc sql;
create table &bedout as
select a.*,
b.&chr_var as new_&chr_var,
b.&st_var as new_&st_var,
b.&end_var as new_&end_var
from &bedin as a
left join
&bedout as b
on a.&chr_var=b.&chr_var and 
     (a.&st_var between b.&st_var and b.&end_var) and
		 (a.&end_var between b.&st_var and b.&end_var);
%end;

%mend;
/*Demo codes:;
data a;
input chr st end;
cards;
1 10 200
1 30 400
1 50 800
2 3 10
2 5 400
2 50 800
;

data a;
input chr st end;
cards;
1 1 5
1 10 20
1 30 400
1 15 50
1 50 800
2 3 10
2 5 400
2 50 800
3 10 1000
3 5000 10000
;

%debug_macro;

%MergerOverlappedRegInBed(
bedin=a,
chr_var=chr,
st_var=st,
end_var=end,
bedout=merged_a,
add_original_bed=1,
dist2st=-100,
dist2end=100
);
*/
