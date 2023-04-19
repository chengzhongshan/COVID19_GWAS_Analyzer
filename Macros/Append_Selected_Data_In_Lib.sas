%macro Append_Selected_Data_In_Lib(lib,excel,excluded,add_dsd_name,dsd_not_contain_rgx,dsdout);
%let re=%sysfunc(prxparse(s/ /" "/oi));
%let rm_list=%sysfunc(prxchange(&re,-1,&excluded));
%let n_rgx=%eval(%sysfunc(count(&dsd_not_contain_rgx,%str( )))+1);
%syscall prxfree(re);

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

proc sql noprint;
select count(*) into: n
 from temp_xyz;
select memname 
        into: name1 - %sysfunc(compress(:name&n))
 from temp_xyz;

%if (&excel=1) %then %do;
select cat(%str("&lib"),'."',strip(memname),'"',strip('n'))
        into: dsd1 - %sysfunc(compress(:dsd&n))
 from temp_xyz;
%end;
%else %do;
select cat(%str("&lib"),'.',strip(memname))
        into: dsd1 - %sysfunc(compress(:dsd&n))
 from temp_xyz;
%end;

data &dsdout;
%if (&add_dsd_name ne) %then %do;
%str(length &add_dsd_name) $15.;
set %do i=1 %to &n;
    &&dsd&i %str(%(in=xyz&i%))
    %end;;
%end;
%else %do;
set %do i=1 %to &n;
    &&dsd&i %str(%(in=xyz&i%))
    %end;;
%end;
%do i=1 %to &n;
if %str(a&i) then %str(&add_dsd_name)=%str("%sysfunc(compbl(&&name&i))");
%end;;
run;

proc datasets lib=work nolist;
delete temp_xyz;
run;

%mend;

/*
%let workdir=I:\SASGWASDatabase;
libname Pooled excel "&workdir\MoDC_Table S4 cis eQTLs and reQTLs from pooled analysis.xls" mixed=yes SCAN_TEXT=NO;
%Append_Selected_Data_In_Lib(lib=pooled,excel=1,excluded=,add_dsd_name=dsd_name,dsd_not_contain_rgx=FilterDatabase tagged Meta,dsdout=DC_Pooled_Analysis);
%Append_Selected_Data_In_Lib(lib=pooled,excel=1,excluded=,add_dsd_name=dsd_name,dsd_not_contain_rgx=FilterDatabase tagged Baseline LPS FLU IFNb,dsdout=DC_Pooled_Analysis_Meta);
libname Pooled clear;
*/
