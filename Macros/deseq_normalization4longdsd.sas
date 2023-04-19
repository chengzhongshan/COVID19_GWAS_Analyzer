%macro deseq_normalization4longdsd(
indsd=a,
outdsd=z,
key4row=r,
key4col=c,
val_var=val
);
data &indsd;
set &indsd;
/* if &val_var=0 then &val_var=.; */
if &val_var=0 then delete;
run;
*get geomean;
proc sql;
create table row_geomean as
select distinct &key4row, exp(mean(log(&val_var))) as geo_mean 
from &indsd 
group by &key4row;

data &indsd (drop=geo_mean rc);
   length &key4row 8;
   length geo_mean 8;
   if _N_ = 1 then do;
      /* load SMALL data set into the hash object */
     declare hash h(dataset: "work.row_geomean");
      /* define SMALL data set variable K as key and S as value */
      h.defineKey("&key4row");
      h.defineData('geo_mean');
      h.defineDone();
      /* avoid uninitialized variable notes */
      call missing(&key4row,geo_mean);
   end;

/* use the SET statement to iterate over the LARGE data set using */
/* keys in the LARGE data set to match keys in the hash object */
set &indsd;
rc = h.find();
if (rc = 0) then &val_var=&val_var/geo_mean;
run;

*Get median for the match dsd by c;
proc sql;
create table column_median_dsd as
select distinct &key4col, median(&val_var) as col_median
from &indsd
group by &key4col;

*divide all value by col_median and multiply the value back with geo_mean;
data &outdsd(drop=rc1 rc2 geo_mean  col_median);
length &key4row 8.;
length geo_mean 8.;
length &key4col 8.;
length col_median 8.;
if _n_=1 then do;
/*Load two small data sets into 2 hashes*/
declare hash rhash(dataset: "work.row_geomean");
      /* define SMALL data set variable K as key and S as value */
      rhash.defineKey("&key4row");
      rhash.defineData('geo_mean');
      rhash.defineDone();
      /* avoid uninitialized variable notes */
      call missing(&key4row,geo_mean);
declare hash chash(dataset: "work.column_median_dsd");
       chash.definekey("&key4col");
       chash.definedata('col_median');
       chash.definedone();
       call missing(&key4col,col_median);
end;
set &indsd;
rc1 = rhash.find();
rc2 = chash.find();
if (rc1 = 0 and rc2 = 0) then &val_var=round(&val_var*geo_mean/col_median);
run;
%mend;

/*Demo:

data a;
do r=1 to 5e2;
 do c=1 to 1e3;
   val=rand('normal');
   if abs(val)>0.1 then output;
 end;
end;
run;

*work on a dataset and compare with the truth results;
data a;
input g $ x1-x9;
cards;
a 1 0 4 5 6 7 8 9 10
b 3 0 4 6 8 9 10 11 30
c 4 5 0 1 0 2 3 4 10
;
run;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

option mprint symbolgen mlogic;
*Note: the output can be the same dsd;
%deseq_normalization(
dsdin=a,
read_vars=_numeric_,
dsdout=a_norm,
readcutoff=0,
cellcutoff=1
);
proc print data=a_norm;run;


data a;
input g $ x1-x9;
r=_n_;
cards;
a 1 0 4 5 6 7 8 9 10
b 3 0 4 6 8 9 10 11 30
c 4 5 0 1 0 2 3 4 10
;
run;
proc sort data=a;by g;
proc transpose data=a out=aa(rename=( col1=val));
var x1-x9;
by r;
run;
data aa(drop=_name_);
set aa;
c=prxchange('s/x//',-1,_name_)+0;
run;

%deseq_normalization4longdsd(
indsd=aa,
outdsd=z,
key4row=r,
key4col=c,
val_var=val
);

proc print data=z;run;

*/

