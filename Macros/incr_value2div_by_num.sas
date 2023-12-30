*Note: this macro will get the smallest value that can be moded by the input denominator;
*If the macro get_value_or_fold=0, then the smallest fold is retured;
*otherwise, the smallest value that can be divided will be kept!;
%macro incr_value2div_by_num(
numerator=101,
denominator=2,
get_value_or_fold=0 /*default value is 0 to get the fold for 
the increased value that can be divided by the denominator*/
);
%if &get_value_or_fold=0 %then %do;
  %sysevalf(&numerator/&denominator,ceil)
%end;
%else %do;
  %sysevalf(%sysevalf(&numerator/&denominator,ceil)*&denominator)
%end;

%mend;

/*Demo code:

%put %incr_value2div_by_num(
numerator=101,
denominator=2,
get_value_or_fold=0
);

%put %incr_value2div_by_num(
numerator=101,
denominator=2,
get_value_or_fold=1
);

*/

