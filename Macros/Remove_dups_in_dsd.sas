%macro Remove_dups_in_dsd(dsd,sort_var,key_var,first_or_last4dup,dsdout,sort_var_cutoff_func);
/*sort the values of sort_var and keep all structure with the first or last unique*/
/*values of key_var;*/
/*first_or_last=1 will keep first unique value that sorted ascendingly */
/*first_or_last=0 will keep last unique value that sorted ascendingly;*/
/*key_var will be applied with unique to keep unique keys;*/
data dsd;
set &dsd;
run;
proc sort data=dsd;
by &key_var &sort_var;
run;
data &dsdout;
set dsd;
by &key_var;
%if &sort_var_cutoff_func ne %then %do;
 %if &first_or_last4dup %then %do;
  if first.&key_var and &sort_var &sort_var_cutoff_func;
 %end;
 %else %do;
  if last.&key_var and &sort_var &sort_var_cutoff_func;
 %end;
%end;
%else %do;
 %if &first_or_last4dup %then %do;
  if first.&key_var;
 %end;
 %else %do;
  if last.&key_var;
 %end;
%end;

run;

%mend;
/*
%Remove_dups_in_dsd(dsd=dsd4matlab
                   ,sort_var=BLCAENRICHMENT
                   ,key_var=TF
                   ,first_or_last4dup=0
                   ,dsdout=dsd
);
*/
