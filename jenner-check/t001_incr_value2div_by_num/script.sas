/* Exercises Macros/incr_value2div_by_num.sas — a small utility from
 * the COVID19_GWAS_Analyzer toolkit that returns either the smallest
 * integer fold (ceil(N/D)) or the smallest value divisible by D.
 *
 * Useful for partitioning genome-wide signal counts into balanced
 * bins (for example, when sizing an axis or laying out a grid of
 * sub-Manhattan plots).
 */

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

/* Demo cases drawn from the macro's own annotations, plus a couple
 * GWAS-flavoured ones (e.g. how many 50-SNP panels for 327 hits). */
%let r1 = %incr_value2div_by_num(numerator=101, denominator=2,  get_value_or_fold=0);
%let r2 = %incr_value2div_by_num(numerator=101, denominator=2,  get_value_or_fold=1);
%let r3 = %incr_value2div_by_num(numerator=15,  denominator=4,  get_value_or_fold=0);
%let r4 = %incr_value2div_by_num(numerator=15,  denominator=4,  get_value_or_fold=1);
%let r5 = %incr_value2div_by_num(numerator=327, denominator=50, get_value_or_fold=0);
%let r6 = %incr_value2div_by_num(numerator=327, denominator=50, get_value_or_fold=1);

data results;
length name $40;
name='ceil(101/2)';      value=&r1; output;
name='ceil(101/2)*2';    value=&r2; output;
name='ceil(15/4)';       value=&r3; output;
name='ceil(15/4)*4';     value=&r4; output;
name='ceil(327/50)';     value=&r5; output;
name='ceil(327/50)*50';  value=&r6; output;
run;

proc print data=results;
run;
