%macro debug_macro(
undebug=0 /*give 1 to reset macro debugging parameters;*/
);
%if &undebug=0 %then %do;
options mprint symbolgen mlogic;
%end;
%else %do;
option nomprint nosymbolgen nomlogic;
%end;
%mend;

/*Demo: 

%debug_macro;

%debug_macro(undebug=1);

*/
