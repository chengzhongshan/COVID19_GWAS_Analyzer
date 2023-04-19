%macro pull_column(dsd,dsdout,cols2pull);

%check_col_orders(dsd=&dsd,colorder_info_out=colinfo,print_colobs=10);

proc sql noprint;
select count(*) into: tot
from colinfo;
select NAME into: v1 - : v%sysfunc(left(&tot))
from colinfo;

*replace numbers with linker to consective numbers;

%get_consecutive_num4linker(nums_with_linker=&cols2pull, global_macro_out=numbers, linker=-);
%let cols2pull=&numbers;

*generate macro var for these vars subject to extraction;
%let columnsInOrder=;
%let x=1;
%do %while (%scan(&cols2pull,&x,' ') ne );
  %let idx=%scan(&cols2pull,&x,' ');
  %let columnsInOrder=&columnsInOrder &&v&idx;
  %let x=%eval(&x+1);
%end;

data &dsdout;
retain &columnsInOrder;
set &dsd;
keep &columnsInOrder;
run;


%mend;


/*Demo:;

%pull_column(dsd=A,dsdout=x,cols2pull=1 2 3-4 6 7-9 10);

*/
