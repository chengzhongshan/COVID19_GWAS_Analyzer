%macro get_top_signal_within_dist(
dsdin=,
grp_var=,
signal_var=,
select_smallest_signal=1,
pos_var=,
pos_dist_thrshd=,
dsdout=,
signal_thrshd=1e-4 /*filter the input dsdin by &signal_val <= &signal_thrshd*/
);

data &dsdout;
length Key $200.;
set &dsdin;
dis_st=&pos_var-&pos_dist_thrshd*0.5;
dis_end=&pos_var+&pos_dist_thrshd*0.5;
Key=catx(':',&grp_var,&pos_var);
where &signal_var <= &signal_thrshd;
run;

proc sort data=&dsdout;by &grp_var &signal_var;run;

proc sql;
create table map_dups2tops as
select a.*,b.Key as _Key_,b.&signal_var as _&signal_var._
from &dsdout as a
left join
&dsdout as b
on a.&grp_var=b.&grp_var and 
   a.&pos_var between b.dis_st and b.dis_end;


%if &select_smallest_signal=1 %then %do;
data map_dups2tops;
set map_dups2tops;
if &signal_var<=_&signal_var._ then do;
   _&signal_var._=.;
end;
if Key=_Key_ then do;
   _key_="";
end;
run;
*Get these overlapped but not the topest signals;
data map_dups2tops_1;
set map_dups2tops;
if _&signal_var._^=.;
*Keep these Key not have the topest signal;
data map_dups2tops_1;
set map_dups2tops_1;
if _&signal_var._<&signal_var then do;
_key_=key;
end;
run;
%end;
%else %do;*Select the largest signal;
data map_dups2tops;
set map_dups2tops;
if &signal_var>=_&signal_var._ then do;
   _&signal_var._=.;
end;
if Key=_Key_ then do;
   _key_="";
end;
run;
*Get these overlapped but not the topest signals;
data map_dups2tops_1;
set map_dups2tops;
if _&signal_var._^=.;
*Keep these Key not have the topest signal;
data map_dups2tops_1;
set map_dups2tops_1;
if _&signal_var._>&signal_var then do;
_key_=key;
end;
run;
%end;

*Exclude these not topest signals from the original data set;
proc sql;
create table &dsdout as 
select a.*
from &dsdout as a
where a.key not in (
 select _key_
 from map_dups2tops_1
);

/*Need to revise it later if having time;
*The above has a small bug;
*This is with problem, as it is only select only one if there are more independent signal in the same group;
*/

%if &select_smallest_signal=1 %then %do;
proc sort data=&dsdout;by &grp_var &signal_var;run;
%end;
%else %do;
proc sort data=&dsdout;by &grp_var descending &signal_var;run;
%end;

proc sort data=&dsdout dupout=dups nodupkeys;by &grp_var;run;
proc sql;
create table dups2tops as
select a.*,b.&pos_var as &pos_var._
from dups as a
left join
&dsdout as b
on a.&grp_var=b.&grp_var and 
   a.&pos_var between b.dis_st and b.dis_end;

data dups2tops;
set dups2tops;
if &pos_var._=.;
run;

data &dsdout;
set &dsdout dups2tops;
drop &pos_var._;
run;



%mend;

/*Demo;

data tops;
input chr $ P BP;
cards;
2 0.001 1
2 0.011 40
2 0.00001 1000
2 0.0005 1500
2 0.001 3000000
2 0.001 90
2 0.01 40000
2 0.00001 10000
2 0.0005 150000
2 0.001 300000000
;
run;
*proc print;run; 

options mprint mlogic symbolgen;

%get_top_signal_within_dist(dsdin=tops
                           ,grp_var=chr
                           ,signal_var=P
                           ,select_smallest_signal=1
                           ,pos_var=BP
                           ,pos_dist_thrshd=1000000
                           ,dsdout=tops1
                           ,signal_thrshd=1e-6);
*/

