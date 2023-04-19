%macro AnyOf(vars=, calculated=, cond=eq 1);
    %local mc mv n v;
    %local allvars var;

    %if %length(%superq(vars)) eq 0 %then %let mv = 0;
    %else %let mv = %ntokens(&vars);

    %if %length(%superq(calculated)) eq 0 %then %let mc = 0;
    %else %let mc = %ntokens(&calculated);

    %let allvars = &vars &calculated;
    %let n = %eval(&mv + &mc);

    %do v = 1 %to &n;
        %let var = %scan(&allvars, &v);
        %if &v gt 1 %then %do;
            or
        %end;
        %if &v gt &mv %then %do;
            calculated
        %end;
        &var &cond
    %end;
%mend AnyOf;

/*Demo:
read it from %SumOf
*/


/*vars and calculated:	list of variables for which the mean (or the sum) will be returned; */
/*the calculated component refers to previously calculated variables (within the same SELECT statement) */
/*while the vars component refers to variables as originally coded in the processed table (or data set).*/

/*cond: specifies the condition that needs to be met by any of the listed variables for the result to be true (1).*/
/*The last argument of %AnyOf.*/
/*Default is eq 1, that is, it checks that any of the listed variables is equal to one.*/

/*Demo:
options mprint mlogic symbolgen;

proc sql;
  create table NewTable as
  select idNumber, x, y,
  abs(x) as absoluteX,
  %MeanOf(variables=u v) as uvMean,
  %MeanOf(variables=a, calculated=absoluteX) as aAbsXMean,
  %NOf(vars=Q1Score Q2Score Q3Score Q4Score Q5Score) as nAnsweredQuestions,
  10*Q3Score as Q3Score,
  5*Q5Score as Q5Score,
  %SumOf(variables=Q1Score Q2Score Q4Score, calculated=Q3Score Q5Score) as TotalScore,
  %AnyOf(vars=Q1Score Q2Score Q3Score Q4Score Q5Score, cond=gt 10) as AnyScoreGreaterThan10,
  from SourceData;
quit;

*/
