%macro nums_in_range_adj_scale(
st,/*start value that can be negative and position*/
end,/*end value*/
by,/*by value for each step; make sure it is matchable with st and end values*/
outmacrovar,/*created a global macro var containing linked nums by space for later access*/
filter4scaledvals=%str(>0),/*Only apply the scaling to specific numbers met the filter*/
scale=2,/*integer num to scale down the nums, i.e., num/scale, that will be in the final macro var*/
quote=1 /*quote the nums and separated by space in the final macro var*/
);
				%global &outmacrovar;
				*This make the format include larger or negative numbers;
				/**Note: sometimes the negative numbers may be out of range of the format;
				%let numlength=%eval(%length(&end)+1);
                                %if %eval(&numlength<3) %then %let numlength=3;
                                */
                                *Use 8 as the default, which is even better, as the above will missing numbers, such as 0.666;
                                %let numlength=8;
				
				data range;
				*Make sure not to use if condition within the do loop in datastep;
				*otherwise, sas will run forever within the do loop!;
				do i=&st to &end by &by;
                                  output;
                                end;
                                run;

                                *Filter data and replace these selected values that can not be modded by scale value;
                                data range;
                                set range;
                                ord=_n_;
				 *scale the value i by scale;
                                 if i &filter4scaledvals then do;
                                    *Only keep these numbers can be modded by the &scale;
                                    if mod(i,&scale)=0 then i=i/&scale;
                                    else i=round(i/&scale,0.1);
                                 end;
				run;
				proc sql noprint;
				%if %eval(&quote=1) %then %do;
				  select quote(prxchange("s/^\./ /",-1,trim(left(put(i,&numlength..1))))) 
                                  into: &outmacrovar separated by " "
                                %end;
				%else %do;
			          select prxchange("s/^\./ /",-1,trim(left(left(put(i,&numlength..1))))) into: &outmacrovar separated by " "
				%end;
				from range
				order by ord;
				drop table range;
				quit;

/*                              Can not replace these missing values as blank space, as later the global macro var seems be changed as local   */
/*				%let &outmacrovar=%sysfunc(rgxchange(s/\./ /,-1,&&&outmacrovar));                                              */

				%put generated numbers for the range from &st to &end by &by are: &&&outmacrovar;
%mend;
/*Demo:

options mprint mlogic symbolgen;

%macro nums_in_range_adj_scale(
st,
end,
by,
outmacrovar,
filter4scaledvals=%str(>0),
scale=2,
quote=1 
);

*/
