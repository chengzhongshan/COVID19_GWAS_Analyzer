
%macro Mult_BED_Enrichment(bed_db,
                        query_db,
						query_var_name,
						random_db,
						random_var_name,
						np,
						sampling_dsdout,
						fdr_dsd_out,
						by_var4bed_db,
						output_mut_summary,
						Uniq_match_only
);

/*only count unique match when query columns in database*/
/*containing multiple bedfiles*/
%if &Uniq_match_only eq %then %do;
 %let Uniq_match_only=1;
%end;

/*This var by_var4bed_db will be used to summarize query result by it*/
%if &by_var4bed_db eq %then %do;
	 %let by_var4bed_db=memname;
%end;
%put This var &by_var4bed_db will be used to summarize query result by it;

/*remove duplicated lines in query_db*/
%put Going to eliminate duplicated lines in query db query_db;
data query_db;
set &query_db;
proc sort data=query_db nodupkeys;
by _all_;
run;
/*label=compbl(strip(left(chr))||":"||strip(left(st))||"-"||strip(left(end)));*/
/*count real querys and sample the same number of mutations in nonquery dsd*/

%if %sysfunc(exist(&sampling_dsdout)) %then %do;
 %put Your sampling dsd &sampling_dsdout has made previously.;
%end;
%else %do;

 proc sql noprint;
 select count(unique(&query_var_name)) into: total
 from query_db;
/* sampling and inviting new var gp_perm into dsdout*/
 %Sampling(indsd=&random_db,n=&total,nperm=&np,dsdout=x);
 /*Genereate dsd containing &random_var_name, chr and Pos for querying in db*/
 %StandardizeVarscanIDs(VarscanID_dsd=x,VarName=&random_var_name,outdsd=&sampling_dsdout);
%end;

/*standardize query dsd and asign 0 value of gp_perm to query_db*/
/*if random_var_name exist in query_db,drop it*/
/*make sure to add libname for query_db*/
%KeepColNotMatchingRgx(indsd=work.query_db,Rgx=(_&random_var_name._|chr|_chr_|pos),outdsd=query_db);
data query;
set query_db;
gp_perm=0;
run;
%StandardizeVarscanIDs(VarscanID_dsd=query,VarName=&query_var_name,outdsd=query);

%if (&np>1) %then %do;
data &sampling_dsdout;
set &sampling_dsdout;
rename &random_var_name=&query_var_name;;
run;
/*combine query dsd with sampling dsd*/
%union_add_tags(dsds=query &sampling_dsdout,     /*Name of the datasets, separated by space    */
                       out=query_combined       /*Name of combined data set     */);
data query;
set query_combined(keep=chr Pos gp_perm &query_var_name _mut_);
run;
%end;
%else %do;
/*data query(keep=chr Pos gp_perm &query_var_name _mut_);*/
/*set query;*/
/*run;*/
%end;

%if &np>100 %then %do;
options nonotes nosource;
%do i=0 %to &np;
%put process query &np of &query_db;
/*make sure the key4range_in_base and key4range_in_query_dsd are the same type,*/
/*which will be used to test equality in where condition*/
%QueryRangeDsd(base_dsd=&bed_db,
                     key4range_in_base=chr,
                     st4range_in_base=st,
                     end4range_in_base=end,
					 extra_vars_in_base2keep=&by_var4bed_db,
                     query_dsd=query(where=(gp_perm=&i)),
                     key4range_in_query_dsd=chr,
					 Pos4lookup_in_query_dsd=Pos,
                     outdsd=result&i);
/*the above macro invite new variables: matched_range and &by_var4bed_db*/
%if &i>0 %then %do;
data result;
set result result&i;
run;
%end;
%else %do;
data result;
set result0;
run;
%end;
%end;
options notes source;
%end;
%else %do;
%put query all together for &query_db;
%QueryRangeDsd(base_dsd=&bed_db,
                     key4range_in_base=chr,
                     st4range_in_base=st,
                     end4range_in_base=end,
					 extra_vars_in_base2keep=&by_var4bed_db,
                     query_dsd=query,
                     key4range_in_query_dsd=chr,
					 Pos4lookup_in_query_dsd=Pos,
                     outdsd=result);
/*%Query_LargeRangeDsd_With_Idx(base_db=&bed_db,*/
/*                     num_key4range_in_base=chr,*/
/*                     st4range_in_base=st,*/
/*                     end4range_in_base=end,*/
/*                     query_dsd=query,*/
/*                     num_key4range_in_query_dsd=chr,*/
/*		             Pos4lookup_in_query_dsd=Pos,*/
/*                     outdsd=result);*/
%end;

/*Summarize mutations by bed &by_var4bed_db and gp_perm;*/
/*
It seems that if we calculate enrichment over duplicated beds belonging to
a specific feature (here V7), the enrichment will be underestimated,
due to the fact that we do not take into account the duplication in query var
and there would be more matched vars in QUERY dsd to be removed for the same 
feature!
Thus, it would be a good idea to keep these bed with >=10 matched muts 
in read query dsd for enrichment analysis.
We also need not to remove duplicates in COUNT
*/

%if &Uniq_match_only=0 %then %do;
/*count ALL matches*/
proc sql ;
create table matched_sum as
select count(&query_var_name) as total,gp_perm,&by_var4bed_db
from result
group by gp_perm,&by_var4bed_db;
%end;
%else %do;
/*only count unique match*/
proc sql ;
create table matched_sum as
select count(unique(&query_var_name)) as total,gp_perm,&by_var4bed_db
from result
group by gp_perm,&by_var4bed_db;
%end;

/*Put unique bed &by_var4bed_dbs into table*/
create table beds as
select unique(&by_var4bed_db) as &by_var4bed_db
from result;

/*0 gp_perm is for original dsd*/
data tmp;
do gp_perm=0 to &np;
  output;
end;
run;
/*recurrsively map perm data with bed &by_var4bed_db*/
proc sql;
create table tmp as
select a.*,b.*
from tmp as a,
     beds as b;
/*map perm and &by_var4bed_db with matched_sum*/
proc sql;
create table All as
select a.*,b.total
from tmp as a
left join
matched_sum as b
on a.gp_perm=b.gp_perm and 
   a.&by_var4bed_db=b.&by_var4bed_db;
/*asign 0 to missing value*/
data All;
set All;
if total=. then total=0;
run;
/*map perm data with real data by &by_var4bed_db*/
proc sql;
create table All_Rev as
select a.*,b.total as Real
from (
 select &by_var4bed_db,total
  from All
  where gp_perm>0
) as a,
(
  select &by_var4bed_db,total
  from All
  where gp_perm=0
) as b
where a.&by_var4bed_db=b.&by_var4bed_db;

/*output fdr and enrichment score*/
proc sql;
create table &fdr_dsd_out as
select &by_var4bed_db,sum(total>Real)/count(*) as FDR,mean(Real) as Matched,mean(total) as avg_permn,
       sum(Real)/sum(total) as enrichment,"&fdr_dsd_out" as query_name
from All_Rev
group by &by_var4bed_db
;

/*keep all matched mutation for later usage*/
%if &output_mut_summary=1	%then %do;
data &fdr_dsd_out._Muts;
set result;
dsd="&fdr_dsd_out";
run;
data &fdr_dsd_out._N;
set All_rev;
dsd="&fdr_dsd_out";
run;
%end;

proc datasets lib=work nolist;
delete result:;
run;

options compress=no;
%mend;

/*


*options mprint mlogic symbolgen;

libname VAF "D:\F_tmp\NewTCGAAssocRst\VAF_SAS";
libname chip "D:\F_tmp\cistrome_beds";
data Polr2a;
set chip.Polr2a(obs=100);
run;
%Mult_BED_Enrichment(bed_db=VAF.features19,
                        query_db=Polr2a,
						query_var_name=SNP,
						random_db=chip.All_drivers_want1,
						random_var_name=&random_var_name,
						np=30,
						sampling_dsdout=samplingdsd,
						fdr_dsd_out=z,
                        by_var4bed_db=,
                        output_mut_summary=,
                        Uniq_match_only=1
);


*Will not do sampling and enrichment analysis;
%Mult_BED_Enrichment(bed_db=VAF.features19,
                        query_db=Polr2a,
						query_var_name=SNP,
						random_db=,
						random_var_name=,
						np=,
						sampling_dsdout=,
						fdr_dsd_out=z,
                        by_var4bed_db=,
                        output_mut_summary=,
                        Uniq_match_only=1
);
*/
