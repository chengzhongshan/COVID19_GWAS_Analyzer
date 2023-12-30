%macro rename_cols_with_macro_vars(
/*Function annotation: this macro is good for renaming large number of columns without trunction in a macro var;
Pleade use symputx('mvname',value,'G') to make global macro variables for this macro;
*/
totcols,
dsd,
colvar_prefix,
macro_var_prefix
);
data &dsd;
set &dsd;
*Rename column names;
%do i=1 %to &totcols;;
%let _v_=&macro_var_prefix.&i;
%let _vv_=%left(&&&_v_);
rename &colvar_prefix.&i=&colvar_prefix.&_vv_;
%end;
run;
%mend;

/*Demo codes:;

*First, it is necessary to create these global vars with the same prefix;
%make_global_vars_with_prefix(vtot=20,varname=var_si);
%put &var_si1;
*No need to run the above for dosubl to make global macro variables;
*as the symputx would be much quicker than the dosubl command;


data b;
infile cards;

array _r{100} _temporary_ (1:100);
array _subr{20} _temporary_;

if _n_=1 then do;
  _iorc_=2718; * random seed ;
  call ranperm(_iorc_, of _r[*]);
  do si=1 to 20;
    _subr{si}=_r{si};
   *Save the column order into the macro var with the corresponding order in the array _subr;
   call symputx('var_si'||left(put(si,8.)),_r{si},'G');
 *The above failed to generate global variables if not providing the 3rd paramerer G;
 *The following works but it is too slow;
 *rc=dosubl('%let var_si'||left(put(si,8.))||'='||_r{si}||';');
  end;
end;


input g :$2. @;
array X{20} V1-V20;
do i=1 to 100;
 
 *Only focus on the randomly selected 20 columns;
  if i in _subr then do;
   ai+1;
   input exp @;X{ai}=exp;
  end;
  else do;
  *Need to input the same var but not output it;
   input exp @;
 end;
end;

*drop si i ai exp rc;
drop si i ai exp;

cards;
a 1.07853 -1.18963 0 -0.91864 -0.94480 0 0.19676 0.60198 0 -0.12117 0.17500 0 -1.53425 -1.12415 0 0.49008 0.75243 0 -0.29045 -1.74954 0 -0.10961 0.64800 0 -0.082133 -1.22114 0 2.25838 -0.56985 0 0.15569 0.77042 0 -0.79959 1.23583 0 0.95013 -0.71323 0 -0.12412 -0.77303 0 -0.59936 -1.25273 0 -1.02456 -.00893172 0 0.20697 1.01989 0 0.67620 0.97901 0 0.57709 -0.30103 0 0.66473 0.19872 0 -1.77815 1.51722 0 0.50742 1.62486 0 0.18401 -0.16353 0 0.18177 -0.24726 0 0.18793 -0.44024 0 -0.23994 1.83298 0 -0.64158 1.30079 0 1.27328 0.74076 0 0.51874 -1.80973 0 -0.19369 -1.66478 0 0.10156 -1.91169 0 -2.05499 -1.21753 0 -0.068751 -1.45505 0 -0.10953 
;
run;
%put &var_si1;

%rename_cols_with_macro_vars(totcols=20,dsd=b,colvar_prefix=V,macro_var_prefix=var_si);
proc print;run;
*/
