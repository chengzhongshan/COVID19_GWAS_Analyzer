%macro Union_Selected_Data_In_Lib(lib,excluded,dsd_not_contain_rgx,dsdout);
%let re=%sysfunc(prxparse(s/ /" "/oi));
%let rm_list=%sysfunc(prxchange(&re,-1,&excluded));
%let n_rgx=%eval(%sysfunc(count(&dsd_not_contain_rgx,%str( )))+1);
%syscall prxfree(re);
/*default memname char(32), which may be too short*/
proc sql noprint;
create table temp_xyz as
 select *
 from dictionary.tables 
where (libname=upper("&lib") and memname not in %str(%("&rm_list"%)));
data temp_xyz;
set temp_xyz;
memname=prxchange("s/\'//",-1,memname);
run;

%do z=1 %to &n_rgx;
  %let rgx=%sysfunc(scan(&dsd_not_contain_rgx,&z));
  data temp_xyz;set temp_xyz;where memname not contains %str("&rgx");run;
%end;
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

/*

*/
