%macro delmacrovars(macro_var_rgx);
  data vars;
    set sashelp.vmacro;
  run;

  data _null_;
    set vars;
    temp=lag(name);
    if scope='GLOBAL' and   
       substr(name,1,3) ne 'SYS' and 
       temp ne name and
       prxmatch("/&macro_var_rgx/",temp)
       then
      call execute('%symdel '||trim(left(name))||';');
  run;
  proc sql noprint;
  drop table vars;
  quit;

%mend delmacrovars;
/*Demo:
%delmacrovars(macro_var_rgx=median);
*/