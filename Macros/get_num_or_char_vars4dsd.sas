%macro get_num_or_char_vars4dsd(indsd,outdsd,numeric);
%if &numeric=0 %then %do;
  %let var_type=char;
%end;
%else %do;
  %let var_type=num;
%end;

%let dsd_name=%scan(&indsd,-1,'.');
%let dsd_lib=%scan(&indsd,-2,'.');
/*In case of no libname was provided*/
%if %eval(&dsd_lib=) %then %let dsd_lib=work;
proc sql;
create table &outdsd as 
select name,label,format,type
  from dictionary.columns
  where libname=upper("&dsd_lib") and
        memname=upper("&dsd_name") and 
		memtype="DATA" and 
        type="&var_type";
quit;
%mend;
/*Demo codes:;

%get_num_or_char_vars4dsd(indsd=sashelp.class,outdsd=info,numeric=1);
*/
