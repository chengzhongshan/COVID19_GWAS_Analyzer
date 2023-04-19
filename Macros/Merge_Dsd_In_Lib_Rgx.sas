%macro Merge_Dsd_In_Lib_Rgx(lib,excluded,dsd_contain_rgx,comm_vars_rgx,dsdout);
%let n_rgx=%eval(%sysfunc(count(&dsd_contain_rgx,%str( )))+1);
/*default memname char(32), which may be too short*/
proc sql noprint;
create table temp_xyz as
 select *
 from dictionary.tables 
where libname=upper("&lib");

%if "&excluded"^="" %then %do;
data temp_xyz;
set temp_xyz;
memname=prxchange("s/\'//",-1,memname);
if prxmatch("/&excluded/i",memname) then delete;
run;
%end;


data temp_xyz;set temp_xyz;if prxmatch("/&dsd_contain_rgx/i",memname);run;

*Add libname to members;
data temp_xyz;
set temp_xyz;
memname="&lib"||"."||strip(left(memname));
run;
%Make_NoQuote_Var_List_From_Dsd(indsd=temp_xyz,var=memname,sep=" ");
%put &noquote_var_list;

%merge_dsd_by_comm_vars(dsds=&noquote_var_list,     /*Name of the datasets, separated by space    */
                        out=&dsdout,                 /*Name of combined data set     */
                        comm_vars_rgx=&comm_vars_rgx);
proc datasets lib=work nolist;
delete temp_xyz;
run;

%mend;

/*Demo:
*Merge datasets with common variables;
*Will exclude dataset with regular expression;

%Merge_Dsd_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=zscore.*,comm_vars_rgx=_genesymbol_,dsdout=tmp);

*/

