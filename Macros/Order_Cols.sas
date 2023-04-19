*When the varlist is longer than 256 in the select process of proc sql, the macro would break;
*To solove the problem, use the alternative macro %roder_cols;
%Macro Order_Cols(indsd);
%let dsd_name=%scan(&indsd,-1,'.');
%let dsd_lib=%scan(&indsd,-2,'.');

proc sql noprint;
  create table temp as
  select varnum, name, type, length from dictionary.columns
  where libname =upper(%str("&dsd_lib")) and memname = upper(%str("&dsd_name"))
  order by lower(name);
proc sql noprint;
select unique(compress(name)) into: varlist
separated by ","
from temp
order by lower(name);

proc sql noprint;
create table &indsd as
select %str(&varlist)
from &indsd;
%Mend;
/*

options macrogen mlogic mprint symbolgen mfile;
data a;
   length x4 x2 X3 x1 X5 a1 a2 a3 A4 A5 8;
run;

%Order_Cols(indsd=work.A);
*/

