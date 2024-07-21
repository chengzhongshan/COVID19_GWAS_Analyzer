%macro list_ORA(/*Over-representation analysis*/
base_list_dsd=,	/*A data set containing lists of elements associated with specific sets or pathways*/
base_list_var=V1,
query_list_dsd=,	/*Target elements for testing enrichment of elements from the base_list_dsd in the ref_list dsd*/
query_list_var=V1,
ref_list_dsd=,	 /*Reference list data set containing genomewide genes*/
ref_list_var=V1,
perm_n=1000,
enrich_dsdout=enrichment_dsd,
printout=1,
label4ORAtitle=%nrbquote(Over-representation analysis pvalue for query dataset: &base_list_dsd)
);

%let q_nobs=%totobsindsd(&query_list_dsd);
%let b_nobs=%totobsindsd(&base_list_dsd);

%if &b_nobs=0 %then %do;
   %put No obs in the base_list_dsd &base_list_dsd!;
	 %abort 255;
%end;

%let r_nobs=%totobsindsd(&ref_list_dsd);
%if &q_nobs>=&r_nobs %then %do;
					 %put Error: there are less or the same number of obs in the reference list data set &ref_list_dsd!;
					 %abort 255;
%end;
proc sql noprint;
create table _perm_dsd_ as
select a.*,
        case
         when b.&query_list_var=a.&ref_list_var then 1
         else 0
         end as Matched
from &ref_list_dsd as a
left join
&query_list_dsd as b
on a.&query_list_var=b.&ref_list_var;

%ranperm4enrichment_test(
perm_n=&perm_n,
n_gs=&r_nobs,
n_random_cells=&q_nobs,
dsdout=_perm_dsd_1,
transpose_dsd=1
);

data _perm_dsd_;
merge _perm_dsd_:;
run;

proc sql;
create table _perm_dsd_ as 
select a.*
from _perm_dsd_ as a,
        &base_list_dsd as b
where  a.&ref_list_var=b.&base_list_var;

data _perm_dsd_;
set _perm_dsd_;
array X{*} x1-x&perm_n.;
do _xi_=1 to dim(X);
  if X{_xi_}=. then X{_xi_}=0;
end;
drop _xi_;

proc summary data=_perm_dsd_ sum noprint;
var Matched x1-x&perm_n.;
output out=_perm_dsd_frq(drop=_type_ _freq_) 
sum=Matched x1-x&perm_n.;
run; 

proc transpose data=_perm_dsd_frq out=_perm_dsd_frq;
var _numeric_;
run;
/*%abort 255;*/
data
matched(rename=(_name_=real_dsd COL1=real_frq)) 
perm_dsd(rename=(_name_=perm_dsd COL1=perm_frq))
;
set _perm_dsd_frq;
if _name_="Matched" then output matched;
else output perm_dsd;
run;
/*%abort 255;*/
/*%let perm_n=1000;*/
data 	&enrich_dsdout
(keep=perm_p expected_n obs_n enrichment_fc
where=(perm_p>=0)
);
retain n expected_n 0;
set perm_dsd end=eof;
if _n_=1 then do;
 set Matched;
end;
if perm_frq- real_frq >= 0 then n=n+1;
expected_n=expected_n+perm_frq;
/*perm_p=n/&perm_n;*/
if eof then do;
		 perm_p=n/&perm_n;
		 obs_n=real_frq;
		 expected_n=round(expected_n/&perm_n,1);
		 enrichment_fc=obs_n/expected_n;
end;
run;

%if &printout=1 %then %do;
title "%unquote(&label4ORAtitle)";
proc print noobs;run;
%end;

proc datasets lib=work nolist;
delete _perm_dsd:;
run;

%mend;

/*Demo codes:;

data base;
do i=1 to 1000 by 10;
 output;
end;

data query;
do i=1 to 500 by 2;
 output;
end;

*random data set;
data query;
array T{5000} _temporary_ (1:5000);
_iorc_=1;
call ranperm(_iorc_,of T{*});
do _i_=1 to 100 by 2;
			 i=T{_i_};
       output;
end;
drop _i_;
run;


data ref;
do i=1 to 5000;
 output;
end;
run;

%list_ORA(
base_list_dsd=base,
base_list_var=i,
query_list_dsd=query,
query_list_var=i,
ref_list_dsd=ref,	
ref_list_var=i,
perm_n=10000,
enrich_dsdout=enrichment_dsd,
printout=1,
label4ORAtitle=%nrbquote(Over-representation analysis pvalue for query dataset: &base_list_dsd)
);

*/

