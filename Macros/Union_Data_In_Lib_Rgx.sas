%macro Union_Data_In_Lib_Rgx(lib,excluded,dsd_contain_rgx,dsdout);

*Asign fake value to exclude dsd if the var excluded is empty;
%if %length(&excluded)=0 %then %let excluded=_____________;

%let n_rgx=%eval(%sysfunc(count(&dsd_contain_rgx,%str( )))+1);
/* %syscall prxfree(re); */
/*default memname char(32), which may be too short*/
proc sql noprint;
create table temp_xyz as
 select *
 from dictionary.tables 
where libname=upper("&lib");

data temp_xyz;
set temp_xyz;
memname=prxchange("s/\'//",-1,memname);
if prxmatch("/&excluded/",memname) then delete;
run;

data temp_xyz;set temp_xyz;if prxmatch("/&dsd_contain_rgx/i",memname);run;

*Add libname to members;
data temp_xyz;
set temp_xyz;
memname="&lib"||"."||strip(left(memname));
run;
%Make_NoQuote_Var_List_From_Dsd(indsd=temp_xyz,var=memname,sep=" ");
%put &noquote_var_list;
%union_add_tags(dsds=&noquote_var_list,     /*Name of the datasets, separated by space    */
                out=&dsdout                 /*Name of combined data set     */);
proc datasets lib=work nolist;
delete temp_xyz;
run;

%mend;

/*Demo:
*Union but not MERGER datasets with common variables;
*Will add rows from each data set and include dataset name in the output;

%Union_Data_In_Lib_Rgx(lib=work,excluded=,dsd_contain_rgx=zscore.*,dsdout=merged);

*/

