%macro nums_in_range(st,end,by,outmacrovar,quote=1);
				%global &outmacrovar;
				*This make the format include larger or negative numbers;
				*Note: sometimes the negative numbers may be out of range of the format;
				%let numlength=%eval(%length(&end)+1);
				data range;
				do i=&st to &end by &by;
				output;
				end;
				run;
				proc sql noprint;
				%if %eval(&quote=1) %then %do;
				  select quote(trim(left(put(i,&numlength..)))) into: &outmacrovar separated by " "
    %end;
				%else %do;
					 select i into: &outmacrovar separated by " "
				%end;
				from range;
				drop table range;
				quit;
				%put generated numbers for the range from &st to &end by &by are: &&&outmacrovar;
%mend;
	/*Demo:
  options mprint mlogic symbolgen;
		%nums_in_range(st=1,end=4,by=2,outmacrovar=numbers,quote=1);
*/
