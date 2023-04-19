%macro vars_length_dsd(lib=work,dsd=,vars_rgx=,dsdout=,sum_vars_length=0,sum_vars_lengthoutvar=var_length_sum);
%KeepColMatchingRgx(indsd=&lib..&dsd,Rgx=&vars_rgx,outdsd=kept_dsd_tmp,insensitive=1);

proc contents data=kept_dsd_tmp noprint out=_var_length_Dsd(keep=name type length);
proc sort data=_var_length_Dsd;by name;run;
proc sql;
create table &dsdout as
select sum(length) as &sum_vars_lengthoutvar, a.*
from _var_length_Dsd as a
group by type
;

%mend;
/*
options mprint mlogic symbolgen;
*No '()' is allowed in rgx;

%vars_length_dsd(lib=work,
                dsd=x
                ,vars_rgx=_genesymbol_|GSM258610
				,dsdout=y
                ,sum_vars_length=1
                ,sum_vars_lengthoutvar=var_length_sum);

*/



