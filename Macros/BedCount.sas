%macro BedCount(bed,st,end,out);
proc sql;
create table &out as
select sum(&end-&st+1) as total
from &bed;
quit;

data &out;
set &out;
WGS_Pct=total/2897310462;
/*hg19=2897310462 (non-N bases)*/
run;

%mend;
/*Demo:
libname G "G:\";
%BedCount(bed=G.promoter
          ,st=var2
          ,end=var3
          ,out=prom);
*/
