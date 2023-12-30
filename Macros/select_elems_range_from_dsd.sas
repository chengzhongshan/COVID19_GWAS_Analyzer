*Note: this macro will generate;
*double quoted list for the function 'in' for filtering in data step;
*the final list will be saved into macro var(s) with specific prefix;
%macro select_elems_range_from_dsd(
dsdin=,
keyvar=,/*var subjected for making list*/
split_by_fold=0,/*Provide value >1 to separate elements into different batches*/
st_num_in_list=,/*Provide start numeric position for the var to extract in the list*/
end_num_in_list=,/*Provide end numeric position to get the range of elements in the list*/
sort_var4key=,/*default is empty; supply a numberic or char var as the 2nd var along the macro var keyvar
to get unique and sorted key elements to make the list for extraction*/
outmacrovarname_prefix=macro_sublist /*Prefix for making macro variables used later*/
);
data _tmp_;
set &dsdin;
keep &keyvar &sort_var4key;
run;
proc sort data=_tmp_ out=_tmp_(keep=&keyvar &sort_var4key) nodupkeys;
by &keyvar &sort_var4key;
run;

proc sql noprint;
select quote(trim(left(&keyvar))) into: all_elems separated by ','
from _tmp_
order by &sort_var4key;
select count(*) into: tot_in_list
from _tmp_;
%put All elements (n=%trim(%left(&tot_in_list))) in your list is here:;
%put &all_elems;
/* %abort 255; */

%if &split_by_fold=0 and %length(&st_num_in_list)>0 and %length(&end_num_in_list)>0 
%then %do;

%select_element_range_from_list(
list=%bquote(&all_elems),
st=&st_num_in_list,
end=&end_num_in_list,
sublist=&outmacrovarname_prefix.1,
sep=%str(,)
);

%end;
%else %if &split_by_fold>0 %then %do;
%let tot_num_in_a_batch=%incr_value2div_by_num(
numerator=&tot_in_list,
denominator=&split_by_fold,
get_value_or_fold=1 /*default value is 0 to get the fold for 
the increased value that can be divided by the denominator*/
);
/* %abort 255; */
 %do bi=1 %to &split_by_fold;
  %if %sysevalf(&tot_num_in_a_batch*&bi)>&tot_in_list %then %do;
    %let _end_=&tot_in_list;
  %end;
  %else %do;
    %let _end_=&tot_num_in_a_batch*&bi;
  %end;
/*   %abort 255; */
  %select_element_range_from_list(
  list=%bquote(&all_elems),
  st=%sysevalf(&tot_num_in_a_batch*(&bi-1)+1),
  end=&_end_,
  sublist=&outmacrovarname_prefix.&bi,
  sep=%str(,)
  );
/*   %abort 255; */
 %end;
%end;

%mend;

/*Demo code:;

proc print data=sashelp.cars(obs=10);
run;

%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

*%debug_macro;

%select_elems_range_from_dsd(
dsdin=sashelp.cars,
keyvar=Make,
split_by_fold=2,
st_num_in_list=,
end_num_in_list=,
sort_var4key=Enginesize,
outmacrovarname_prefix=Make_sublist
);
%put &Make_sublist2;

*/




