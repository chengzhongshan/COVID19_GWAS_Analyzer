%macro idx4list_in_alphabet_ord(
list= ,/*Blank space separated elements*/
outdsd=list_order, /*A sas dataset will be created to contain the index
for these elements sorted in alphabet mode*/
index_list_var=idx4list, /*a global macro var will be created to contain these index*/
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

data a;
do i=&idx4list;
 y=i*2;
 output;
end;
run;
proc print;run;

*/

