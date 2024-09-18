%macro pull_list_by_idx(
/*This macro is very useful for pulling elements by using its position index in a lit!*/
list=,/*Blank space separated elements*/
index4list=idx4list, /*index for elements in the list to be extracted*/
sep=%nrbquote( ), /*separator for the input list*/
outlist=_outlist_, /*A global macro var to contain extracted elements in the original order*/
sorted_outlist=_sorted_outlist_  /*A global macro var to contain extracted elements in sortedl order by alphabet*/
/*Note: do not use the same name for outlist and sorted_outlist, as global variables will conflict with local variables*/
);

%if %length(&list)=0 %then %do;
   %put The input list can not be empty;
   %abort 255;
%end;

%if %length(&index4list)=0 %then %do;
   %put The input index4list can not be empty;
   %abort 255;
%end;

%global &outlist;
%if %symexist(&outlist) %then %do;
					 %put WARNING: previous global macro var &outlist exist!;
%end;

%global &sorted_outlist;

%rank4grps(
grps=&list,
dsdout=_list_
);
/*proc print;run;*/
%rank4grps(
grps=&index4list,
dsdout=_idx_
);
/*proc print;run;*/
proc sql;
create table _sublist_ as
select a.*
from _list_ as a,
        _idx_ as b
where a.num_grps=b.num_grps
order by a.num_grps;
/*proc print;run;*/
proc sql noprint;
select grps into:  &outlist separated by " "
from _sublist_ 
order by num_grps;

select grps into:  &sorted_outlist separated by " "
from _sublist_ 
order by char_ord;

%mend;

/*Demo codes:;
%debug_macro;

%pull_list_by_idx(
list=a d b c f g,
index4list=1 2,
sep=%nrbquote( ),
outlist=outlist,
sorted_outlist=sorted_outlist
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

