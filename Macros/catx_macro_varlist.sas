*options symbolgen mprint mlogic;
%global list;
%macro catx_macro_varlist(list,sep);
%let re=%sysfunc(prxparse(s/ /&sep/oi));
%let list=%sysfunc(cat("%sysfunc(prxchange(&re,-1,&list))"));
%put macro variable list now is updated as &list;
%put list can be used with cat or catx;
%syscall prxfree(re);
%mend;

/*
options mprint macrogen mlogic symbolgen mfile;
%catx_macro_varlist(list=famid faminc1,sep=%str(,));
*/
