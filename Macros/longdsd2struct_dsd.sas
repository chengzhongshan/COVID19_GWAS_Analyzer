%macro longdsd2struct_dsd(
indsd,
key1st_var,
key2nd_var,
structdsdout,
max_iteration=100 /*the number of times to recursively perform proc sql to lookup these keys*/
);

*remove duplicates and two keys are the same records;
proc sort data=&indsd(where=(&key1st_var^=&key2nd_var)) nodupkeys;
by &key1st_var &key2nd_var;
run;

%do i=1 %to &max_iteration;

   %if &i=1 %then %do;
    %let basedsd=&indsd;
    %let queryvar=&key2nd_var;
    %let tmpout=&indsd._1;
   %end;
   %else %do;
    %let queryvar=d%eval(&i-1);
    %let basedsd=&indsd._%eval(&i-1);
    %let tmpout=&indsd._&i;
   %end;
   
   proc sql;
   create table &tmpout as
   select a.*,b.&key2nd_var as d&i
   from &basedsd as a
   left join
   &indsd as b
   on a.&queryvar = b.&key1st_var;

   *Check whether all of newly generated var d&i is empty or missing;
   %iscolallempty(dsd=&tmpout,colvar=d&i,outmacrovar=missvar4d&i);
   data &structdsdout;
   set &tmpout;
   run;
   %if &&missvar4d&i=1 %then %return;
   *The above assignment will stop the loop;
%end;

proc sort data=&structdsdout;
by _all_;
run;

%mend;

/*Demo:

%importallmacros;

proc import datafile="Macros.txt" dbms=tab out=x replace;
guessingrows=max;
run;

%longdsd2struct_dsd(
indsd=x,
key1st_var=file,
key2nd_var=Macro_Info,
structdsdout=struct_dsd,
max_iteration=10
);
proc print;run;

*/

