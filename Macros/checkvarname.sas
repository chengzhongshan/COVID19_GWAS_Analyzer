%macro checkvarname(value);
%let position=%sysfunc(notname(value));
%put **** Invalid character in position: $position (0 means &value is okay);
%let valid=%sysfunc(nvalid(&value,v7));
%put 
     **** Can &value be a variable name (0=NO, 1=YES)? &valid;
%put;
%put;
%mend;
/*Demo:

%checkvarname(valid_name);
%checkvarname( valid_name);
%checkvarname(invalid name);
%checkvarname(book_sales_results_for_past_five_years!);

*/
