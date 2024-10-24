%macro nums_in_range_adj_scale(
/*Note: the scale can only be integer with value >=1, as the macro will only be able to scale down the numbers in range!*/
st,/*start value that can be negative and position*/
end,/*end value*/
by,/*by value for each step; make sure it is matchable with st and end values*/
outmacrovar,/*created a global macro var containing linked nums by space for later access*/
filter4scaledvals=%str(>0),/*Only apply the scaling to specific numbers met the filter*/
scale=2,/*integer num to scale down the nums, i.e., num/scale, that will be in the final macro var*/
quote=1, /*quote the nums and separated by space in the final macro var*/
mod_num2keep= /*Default is empty for not filtering these elements by mod; when values, 
such as 2 or 3 are provided, only keep numbers that fulfil the mod(element,num)=0*/
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
                                    *https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/ds2ref/n0t9j8b09x4uphn1kl1i70x63z19.htm;
                                    *If &scale<1, such as 0.3, 10*i/3=>remain*0.1;
                                    if mod(i,&scale)=0 then i=i/&scale;
                                    else i=round(i/&scale,0.1);
                                 end;
				run;

       %if %length(&mod_num2keep)>0 %then %do;
                data range;
                set range;
                *Note: only focus on i passed the filter of i &filter4scaledvals;
                if i &filter4scaledvals and mod(i,&mod_num2keep)^=0 then i=.;
                run;
       %end;
        
       
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

%nums_in_range_adj_scale(
st=1,
end=10,
by=1,
outmacrovar=xx,
filter4scaledvals=%str(>0),
scale=2,
quote=1,
mod_num2keep= 
);

*Remove even numbers as missing;
%nums_in_range_adj_scale(
st=-10,
end=10,
by=1,
outmacrovar=xx,
filter4scaledvals=%str(>0),
scale=2,
quote=1,
mod_num2keep=2 
);


*/
