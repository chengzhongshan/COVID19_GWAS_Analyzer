/* Apply variable names, labels and formats
from dataset indsd to target_dsd */
*options mprint;
%macro Rename_Add_Prefix4Most_Vars(indsd,prefix,excluded,replace_rgx_in_varname=);
*The macro requires to have the input dataset in the format of lib.dsd;
*Note: ensure the excluded vars are in exact lowercase or uppercase as that of the column names of input data set!;

%if %index(&indsd,.) =0	%then %let indsd=work.&indsd;
%put your input dataset is assumed as &indsd;
/*%abort 255;*/
%let dsd_name=%scan(&indsd,-1,'.');
%let dsd_lib=%scan(&indsd,-2,'.');
%let re=%sysfunc(prxparse(s/ /" "/oi));
%let rm_list=%sysfunc(prxchange(&re,-1,&excluded));
%put New String: %sysfunc(prxchange(&re,-1,&excluded));
%syscall prxfree(re);

proc sql noprint;
create table temp as 
select name,label,format
  from dictionary.columns
  where libname=upper("&dsd_lib") and
        memname=upper("&dsd_name") and 
		memtype="DATA";
data temp;
	set temp;
	where name not in %str(%("&rm_list"%));
run;


%if %length(&replace_rgx_in_varname)>0 %then %do;
proc sql noprint;
   select count(*) into :n from temp;
   select cat('rename ',strip(name),
              '= ',%str("&prefix"),strip(prxchange("s/&replace_rgx_in_varname//i",-1,name)),';')
      into :l1 - %sysfunc(compress(:l&n))
      from temp;
%end;
%else %do;
proc sql noprint;
   select count(*) into :n from temp;
   select cat('rename ',strip(name),
              '= ',%str("&prefix"),strip(name),';')
      into :l1 - %sysfunc(compress(:l&n))
      from temp;
%end;
quit;

proc datasets lib=&dsd_lib nolist;
modify &dsd_name;
   %do i = 1 %to &n; 
     &&l&i 
   %end;
run;
%mend;

/*
data faminc;
  input famid faminc1-faminc12 ;
cards;
1 3281 3413 3114 2500 2700 3500 3114 -999 3514 1282 2434 2818
2 4042 3084 3108 3150 -999 3100 1531 2914 3819 4124 4274 4471
3 6015 6123 6113 -999 6100 6200 6186 6132 -999 4231 6039 6215
;
run;

options mprint macrogen mlogic symbolgen mfile;
%Rename_Add_Prefix4Most_Vars(indsd=work.faminc,prefix=x,excluded=famid faminc1,replace_rgx_in_varname=_);

proc print data = faminc heading= h noobs;
run;
quit;
*/
