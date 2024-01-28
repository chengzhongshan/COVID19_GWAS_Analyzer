%macro list_in_list(/*a sas function keeps these query_list that exist in the base_list in the original order*/
query_list=,/*blank space separated elements for querying in the following base_list*/
base_list=/*blank space separated elements treated as a base list to be searched for elements in the query list*/
);
%local new_list;
%let new_list=;
%let nl=%ntokens(&query_list);
%do ni=1 %to &nl;
         %let q=%scan(&query_list,&ni,%str( ));
/*				 %if %sysfunc(prxmatch(/(^&q\b|\b&q\b)/,%bquote(&base_list))) %then %do;*/
				   %if %eval(%_in_(q,&base_list)=1) %then %do;
					 /*It is necessary to put the macro name q but not &q for the %_in_ macro*/
				           %let new_list=&new_list 	&q;
				 %end;
%end;
&new_list;
%mend;

/*Demo codes:;
 %debug_macro;
 %let kept_list=%list_in_list(query_list=4 3,base_list=1 2 3 4 6);
%put &kept_list;
*/
