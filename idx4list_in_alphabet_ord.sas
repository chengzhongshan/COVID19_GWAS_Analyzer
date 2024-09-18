%macro idx4list_in_alphabet_ord(
/*This macro is very useful for obtaining numeric index in an alphabetic sorted list for a query list;
The output idx can be used in a macro loop or in a array at data step!*/
list= ,/*Blank space separated elements*/
outdsd=list_order, /*A sas dataset will be created to contain the index
for these elements sorted in alphabet mode*/
index_list_var=idx4list, /*a global macro var will be created to contain these index
Make sure the value for index_list_var is not index_list_var, as it will lead conflict between
the global macro var and the local macro var with the same name*/
sep=%nrbquote(,) /*separator for the newly created index*/
);
%global &index_list_var;
%let &index_list_var=;
%rank4grps(
grps=&list,
dsdout=&outdsd
);

proc sql noprint;
select char_ord into: &index_list_var separated by "&sep"
from &outdsd;

%mend;

/*Demo codes:;
%debug_macro;

%idx4list_in_alphabet_ord(
list=a c d b f g, 
outdsd=list_order, 
index_list_var=idx4list
);
%put The index for the input list sorted in alphabet order is:;
%put &idx4list;
%put which can be used by a macro do while loop to query elements in other list!;

%let _pvar_list_=;
%let _betavar_list_=;
%let _idx_i_=1;
%do %while (%scan(&idx4gwas_list,&_idx_i_,%str( )) ne );
		%let 	_pvar_list_=&_pvar_list_ %scan(&pvar_list,&_idx_i_,%str( ));
		%let _betavar_list_=&_betavar_list_ %scan(&betavar_list,&_idx_i_,%str( ));
		%let _idx_i_=%eval(&_idx_i_+1);
%end;


data a;
do i=&idx4list;
 y=i*2;
 output;
end;
run;
proc print;run;



*/

