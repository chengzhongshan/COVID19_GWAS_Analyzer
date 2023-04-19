%macro Query_LargeRangeDsd_With_Idx(base_db,
                     num_key4range_in_base,
                     st4range_in_base,
                     end4range_in_base,
                     query_dsd,
                     num_key4range_in_query_dsd,
		             Pos4lookup_in_query_dsd,
                     outdsd);
options nonotes nosource;
%put Going to run SAS Macro Query_LargeRangeDsd_With_Idx;
%put Query dsd is &query_dsd;

*This make the program too slow;
/*
data _query_;
set &query_dsd;
run;
proc sql noprint;			
select count(&num_key4range_in_query_dsd) into: n
from _query_;
*/

proc contents data=&query_dsd noprint out=dsd_info;
run;
proc sql noprint;			
select NOBS+0 into: n
from dsd_info(obs=1);

%put There are &n query ids from &query_dsd;

%do i=1 %to &n;
 /*%abort 255;*/
 *Create macro variables for query;
 proc sql noprint;
 select &num_key4range_in_query_dsd,&Pos4lookup_in_query_dsd into: key,:Pos
 from &query_dsd
 where monotonic()=&i;	

 %if (&i=1) %then %do;
/* Pay attention to three conditions*/
 proc sql noprint;
 	create table &outdsd as
 	select * from &base_db
 	where (
	   &num_key4range_in_base=&key and
	   &st4range_in_base<=&Pos and
	   &end4range_in_base>=&Pos
	);
 %end;
 %else %do;
 /* Pay attention to three conditions*/
  proc sql noprint;
 	create table base&i as
 	select * from &base_db
 	where (
	   &num_key4range_in_base=&key and
	   &st4range_in_base<=&Pos and
	   &end4range_in_base>=&Pos
	);
  proc append base=&outdsd data=base&i;
  run;
  proc datasets lib=work nolist;
  delete base&i;
  run;
 %end;
%end;
%put 'JOB FINISHED';
%let dsd_in=&outdsd;
%delete_empty_dsd(&dsd_in);
options notes source;
%mend Query_LargeRangeDsd_With_Idx;

/*Demo;
libname VAF "D:\F_tmp\NewTCGAAssocRst\VAF_SAS";
libname CHIP "D:\F_tmp\cistrome_beds";
data Q;
set CHIP.Chip_db_tcga(obs=200);
run;
options mprint mlogic symbolgen;
%Query_LargeRangeDsd_With_Idx(base_db=CHIP.Chip_db_tcga,
                     num_key4range_in_base=chr,
                     st4range_in_base=st,
                     end4range_in_base=end,
                     query_dsd=Q,
                     num_key4range_in_query_dsd=chr,
		             Pos4lookup_in_query_dsd=st,
                     outdsd=Query_Result);
*/
