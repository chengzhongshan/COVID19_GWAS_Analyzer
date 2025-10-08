%macro pull_list(input_list,idx4pull,sep=%str( ));
%*both input_list and idx4pull should use the same separator;
%*this macro will generate a new list based on the idx4pull;
%*unlike another macro pull_list_by_idx, this macro will not genrate global variable;
%*containing the elements of the new list, instead which will be assigned to a macro variable by using the statement let;
%local tot_idx idx_i i;
%let tot_idx=%numargs(&idx4pull);
%do i=1 %to &tot_idx;
	   %let idx_i=%scan(&idx4pull,&i,&sep);
      %if &i=&tot_idx %then %do;
			%scan(&input_list,&idx_i,&sep)
	  %end;
	  %else %do;
			 %scan(&input_list,&idx_i,&sep)&sep
	  %end;
%end;

%mend;
/*Demo codes:

*%debug_macro;

%let new_list=%pull_list(I am here for testing,idx4pull=5 4 3 1,sep=%str( ));
%put &new_list;

*/
