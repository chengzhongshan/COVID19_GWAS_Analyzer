%macro numargs(arg);
   %if &arg= %then %do;
        0
      %end;
    %else %do;
       %let n=1;
       %do %until (%qscan(&arg,%eval(&n),%str( ))=%str()); 
         %let n=%eval(&n+1);
       %end;
       %eval(&n-1)
    %end;
%mend numargs;
