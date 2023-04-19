%macro char2num_dsd(dsdin,vars,dsdout);
%let nv=%eval(%sysfunc(count(&vars,%str( )))+1);
%if %index(&vars,%str( )) %then %do;
 %let _vars_=%sysfunc(prxchange(s/ /__ __/,-1,&vars));
%end;
%else %do;
 %let _vars_=%sysfunc(prxchange(s/^/__/,-1,&vars));
%end;

%put old vars are &vars;
%put temperary new vars are &_vars_;
data &dsdout(
  rename=(
  %let n=1;
  %do %while (&n<=&nv);
      %let old0=%scan(&_vars_,&n);
      %let new0=%scan(&vars,&n);
       &old0=&new0 
   %let n=%eval(&n+1);
  %end;
 )
);
set &dsdin;

  %let n=1;
  %do %while (&n<=&nv);
   %let old=%scan(&_vars_,&n);
   %let new=%scan(&vars,&n);
     &old=&new+0;
   %let n=%eval(&n+1);
  %end;

drop &vars;
run;

%mend;
/*options mprint mlogic symbolgen;*/
/*
%char2num_dsd(dsdin=dsd,
              vars=P FDR fdr_mut carriers,
              dsdout=tmp);
*/
