%macro dbquote_vars(vars);
/*%let &vars=CEU YRI;*/
%let re=%sysfunc(prxparse(s/ +/" "/oi));
%let var_list=%sysfunc(prxchange(&re,-1,"&&vars"));
%syscall prxfree(re);
%put &var_list;
&var_list
%mend;

/*
data y;
set sashelp.cars;
where make in (%dbquote_vars(vars=Acura BMW));
run;
*/

