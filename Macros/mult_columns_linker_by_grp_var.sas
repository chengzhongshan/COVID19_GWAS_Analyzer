%macro mult_columns_linker_by_grp_var(
indsd=_last_,
outdsd=Linked_dsd,
grp_var=,/*This var will be treated as key for linking all elements among var2link; Note: only unique element will be kept by the macro*/
vars2link= ,/*separate multiple CHAR vars by space or use var1-varn but not varA--varB to include multiple vars*/
linker=,/*can be , or a blank space; default is ,; provide alternative separator to link these vars*/
output_var4linked_vars=linked_vars /*Name for the var containing linked elements*/
);
%if %length(&linker)=0 %then %let linker=%bquote(,);
*ensure the &indsd is sorted by the 1st column, i.e., varname Macro;
proc sort data=&indsd;by &grp_var;run;

data &outdsd(keep=&grp_var &output_var4linked_vars);
length grp $500. &output_var4linked_vars $1000.;
retain grp '' &output_var4linked_vars '';
*https://support.sas.com/resources/papers/97529_Using_Arrays_in_SAS_Programming.pdf;
array X{*} $500. &vars2link;
set &indsd;
if first.&grp_var then do;
 grp=&grp_var;
 &output_var4linked_vars=catx("&linker", of X{*});
end;
else do;
 &output_var4linked_vars=catx("&linker",&output_var4linked_vars,catx(', ', of X{*}));
end;

*The use of regular expression to remove duplicates does not work very well.;
/**Remove duplicate elements;*/
/*do while (prxmatch("/([^&linker]+)&linker(.*)\b\1/",&output_var4linked_vars));*/
/* &output_var4linked_vars=prxchange("s/([^&linker]+)&linker(.*)\b\1/$1&linker$2/",-1,&output_var4linked_vars);*/
/* &output_var4linked_vars=prxchange("s/&linker+/&linker/",-1,&output_var4linked_vars);*/
/*end;*/
/* *remove the tailing linker if it exists;*/
/* &output_var4linked_vars=prxchange("s/,\s+$//",-1,&output_var4linked_vars);*/

if last.&grp_var then output;
by &grp_var;
run;

*Now use the macro %unique with dosubl to remove duplicates;
data &outdsd(drop=rc);
set &outdsd;
if prxmatch('/\w/',&output_var4linked_vars) then do;
   rc=dosubl('%let _tmpi_'||left(put(_n_,8.))||'=%unique('||&output_var4linked_vars||')');
end; 
else do;
  call symputx('_tmpi_'||left(put(_n_,8.)),'');
end;
run;
data &outdsd;
set &outdsd;
&output_var4linked_vars=symget('_tmpi_'||left(put(_n_,8.)));
run;

%mend;

/*Demo codes:;
proc print data=sashelp.cars(obs=10);run;

%debug_macro;

data x;
set sashelp.cars(obs=20);
run;

%mult_columns_linker_by_grp_var(
indsd=x,
outdsd=Linked_dsd,
grp_var=make,
vars2link=type origin,
linker=,
output_var4linked_vars=linked_vars 
);

*/

