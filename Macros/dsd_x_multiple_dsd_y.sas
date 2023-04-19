

%macro dsd_x_multiple_dsd_y(dsd_x,prefix_dsd_x,dsd_y,dsd_out);

%Rename_Add_Prefix4All_Vars(indsd=&dsd_x,prefix=&prefix_dsd_x);

data &dsd_y;
set &dsd_y;
n=_n_;
run;

proc sql noprint;
select count(*) into: num from &dsd_y;

%do i=1 %to &num;
proc sql noprint;
create table xy&i as
select * from &dsd_x as a,&dsd_y as b
where b.n=&i;
%end;

data &dsd_out;
set xy1-%sysfunc(compress(xy&num));
drop n;
run;

proc datasets lib=work nolist;
delete xy1-%sysfunc(compress(xy&num));
run;

%mend;

/*
data x;
input a b c;
cards;
1 2 3
4 5 6
3 2 1
;
data y;
input a f g;
cards;
0 0 0
1 1 1
2 2 2
;
run;
;
options mprint mlogic symbolgen macrogen;
%dsd_x_multiple_dsd_y(dsd_x=work.x,prefix_dsd_x=x_,dsd_y=work.y,dsd_out=All);
*/
