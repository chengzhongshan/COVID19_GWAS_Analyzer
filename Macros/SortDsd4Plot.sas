%macro SortDsd4Plot(dsd,ByFmtVar,OutFmtVar,OutDsd,GroupVars,SumByVar,CountByVar,MeanByVar);

%if &GroupVars ne %then %do;
proc sort data=&dsd;
by &GroupVars;
run;
proc rank data=&dsd out=_dsd_;
var &ByFmtVar;
ranks rank_&ByFmtVar;
by &GroupVars;
run;
proc sort data=_dsd_;
by &GroupVars rank_&ByFmtVar;
run;

data _dsd_;
set _dsd_;
rank_&ByFmtVar=_n_;
run;

%if &SumByVar ne %then %do;
proc sql;
create table x as
select sum(&ByFmtVar) as tot,&SumByVar
from _dsd_
group by &SumByVar;
create table _dsd_ as 
select a.*,b.tot
from _dsd_ as a
left join
x as b
on a.&SumByVar=b.&SumByVar;
proc sql;
create table &OutDsd as
select a.*,put(b.rank_&ByFmtVar,8.) as &OutFmtVar,b.tot
from &dsd as a
natural join 
_dsd_ as b
order by tot,rank_&ByFmtVar;
%end;
%else %if &CountByVar ne %then %do;
proc sql;
create table x as
select count(&ByFmtVar) as tot,&CountByVar
from _dsd_
group by &CountByVar;
create table _dsd_ as 
select a.*,b.tot
from _dsd_ as a
left join
x as b
on a.&CountByVar=b.&CountByVar;
proc sql;
create table &OutDsd as
select a.*,put(b.rank_&ByFmtVar,8.) as &OutFmtVar,b.tot
from &dsd as a
natural join 
_dsd_ as b
order by tot,rank_&ByFmtVar;
%end;
%else %if &MeanByVar ne %then %do;
proc sql;
create table x as
select avg(&ByFmtVar) as tot,&MeanByVar
from _dsd_
group by &MeanByVar;
create table _dsd_ as 
select a.*,b.tot
from _dsd_ as a
left join
x as b
on a.&MeanByVar=b.&MeanByVar;
proc sql;
create table &OutDsd as
select a.*,put(b.rank_&ByFmtVar,8.) as &OutFmtVar,b.tot
from &dsd as a
natural join 
_dsd_ as b
order by tot,rank_&ByFmtVar;
%end;
%else %do;
proc sql;
create table &OutDsd as
select a.*,put(b.rank_&ByFmtVar,8.) as &OutFmtVar
from &dsd as a
natural join 
_dsd_ as b
order by rank_&ByFmtVar;
%end;

%end;

%else %do;
proc rank data=&dsd out=_dsd_;
var &ByFmtVar;
ranks rank_&ByFmtVar;
run;
proc sort data=_dsd_;
by rank_&ByFmtVar;
run;

data _dsd_;
set _dsd_;
rank_&ByFmtVar=_n_;
run;
proc sql;
create table &OutDsd as
select a.*,put(b.rank_&ByFmtVar,8.) as &OutFmtVar
from &dsd as a
natural join 
_dsd_ as b
order by rank_&ByFmtVar;

%end;


proc datasets lib=work nolist;
delete _dsd: x;
run;

%mend;


/*
data tmp;
set sashelp.cars(obs=10);
run;

options mprint mlogic symbolgen;
%SortDsd4Plot(dsd=tmp,
              ByFmtVar=Horsepower,
              OutFmtVar=x,
              OutDsd=New);



*Important: Only use one of CountByVar,SumByVar, or MeanByVar;
%SortDsd4Plot(dsd=tmp,
              ByFmtVar=Horsepower,
              OutFmtVar=x,
              OutDsd=New,
              GroupVars=make type,
              SumByVar=make);


*/
