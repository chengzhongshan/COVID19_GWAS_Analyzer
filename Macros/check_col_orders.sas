%macro check_col_orders(dsd,colorder_info_out,print_colobs=10);
proc contents data=&dsd out=&colorder_info_out noprint;
run;
data &colorder_info_out;
set &colorder_info_out;
keep name varnum type length format;
rename varnum=column_order;
run;
proc sort data=&colorder_info_out;
by column_order;
run;
data &colorder_info_out;
retain column_order;
set &colorder_info_out;
run;
%if "&print_colobs"="" %then %do;
proc print data=&colorder_info_out;
run;
%end;
%else %do;
proc print data=&colorder_info_out(obs=&print_colobs);
run;
%end;
%mend;


/*Demo:;

%check_col_orders(dsd=A,colorder_info_out=colinfo,print_colobs=10);

*/
