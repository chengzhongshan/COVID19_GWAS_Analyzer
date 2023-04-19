%macro mk_dbquote_varlist(vars_list,sep,output_separator);
 *Remove tailing spaces;
 %let vars_list=%qsysfunc(prxchange(s/\s*$//,-1,&vars_list));
 %if &output_separator eq "" %then %do;
     &output_separator=%str( );*default separator is blank space;
 %end;
 %let new_sep=%str(%'&output_separator%');
 %let re=%sysfunc(prxparse(s/&sep/&new_sep/oi));
 %let quoted_vars_list=%str(%')%upcase(%sysfunc(prxchange(&re,-1,&vars_list)))%str(%');
 %put New vars list: &quoted_vars_list;
 %syscall prxfree(re);
 %str(&quoted_vars_list)
%mend;
/*Note: For space separator, it is necessary to use %str( );
options mprint mlogic symbolgen;
%let new_vars_list=%mk_dbquote_varlist(vars_list=a b-c-d ,sep=%str( ),output_separator=%str(,));
%put &new_vars_list;

*/
