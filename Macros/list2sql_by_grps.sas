%macro list2sql_by_grps(
list=A B C /*Replace blank spaces with comma using %str or %nrstr or %nrbquote*/
);

%sysfunc(prxchange(s/ +/%str(,)/,-1,&list))

%mend;
/*Demo codes:;
%let new_list=%list2sql_by_grps(list=A C);
%put &new_list;
*/

