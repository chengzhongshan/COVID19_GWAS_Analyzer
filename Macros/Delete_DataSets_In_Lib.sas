*options mprint;
%macro Delete_DataSets_In_Lib(lib,excel,excluded,dsd_not_contain_rgx,dsd_contain_rgx);
%let re=%sysfunc(prxparse(s/ /" "/oi));
%let rm_list=%sysfunc(prxchange(&re,-1,&excluded));
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

%if %length(&dsd_not_contain_rgx)>0 %then %do;
data temp_xyz;
set temp_xyz;
patternId=prxparse(%str("/&dsd_not_contain_rgx/i"));
if not prxmatch(patternId,memname);
run;
%end;

%if %length(&dsd_contain_rgx)>0 %then %do;
data temp_xyz;
set temp_xyz;
patternId=prxparse(%str("/&dsd_contain_rgx/i"));
if prxmatch(patternId,memname)>0;
run;
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
select strip(memname)
        into: dsd1 - %sysfunc(compress(:dsd&n))
 from temp_xyz;
%end;

proc datasets lib=&lib nolist;
delete temp_xyz
%do i=1 %to &n;
    &&dsd&i
%end;;
run;
%mend;

/*

%let workdir=I:\SASGWASDatabase;
libname Pooled excel "&workdir\MoDC_Table S4 cis eQTLs and reQTLs from pooled analysis.xls" mixed=yes SCAN_TEXT=NO;

%Delete_DataSets_In_Lib(
lib=pooled,
excel=1,
excluded=,
dsd_not_contain_rgx=FilterDatabase tagged Meta,
dsd_contain_rgx=);

libname Pooled clear;


%Delete_DataSets_In_Lib(
lib=work,
excel=0,
excluded=,
dsd_not_contain_rgx=,
dsd_contain_rgx=(Lcl|dsd)
);

*/
