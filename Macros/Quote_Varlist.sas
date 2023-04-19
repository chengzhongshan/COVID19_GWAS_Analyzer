*options symbolgen mprint mlogic;
%global list;
%macro Quote_Varlist(list);
%let re=%sysfunc(prxparse(s/ /" "/oi));
%let list=%sysfunc(cat("%sysfunc(prxchange(&re,-1,&list))"));
%put macro variable list=&list;
%syscall prxfree(re);
%mend;

/*
options mprint macrogen mlogic symbolgen mfile;
%Quote_Varlist(list=famid faminc1);
*/
