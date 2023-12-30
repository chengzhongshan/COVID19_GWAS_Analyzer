%macro make_global_vars_with_prefix(vtot,varname=var_si,value4var=-9);
%do vi=1 %to &vtot;
  %global &varname.&vi.;
  %let &varname.&vi.=&value4var;
%end;
%mend;

/*Demo codes:;
%make_global_vars_with_prefix(vtot=20,varname=var_si);
%put &var_si1;
*/
