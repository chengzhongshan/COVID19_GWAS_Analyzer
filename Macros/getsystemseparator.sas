%macro getsystemseparator;
   %if (&sysscp=WIN) %then %do;
      %str(/)
   %end;
   %else %do;
      %str(\)
   %end;
%mend;

