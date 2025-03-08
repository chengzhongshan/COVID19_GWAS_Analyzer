%macro AddMissingTag4Grps(
dsdin=,/*Long format dsd with grp vars and numeric value var*/
grp_vars=, /*Group variables used to stratify numeric variable for missing test;
Note: any numeric variable with missing value in a group will lead to the assigment of 
value 1 to the combination of these grp vars, meanwhile, 0 will be supplied the group vars*/
value_var=,	/*Numeric variable subject to missing evaluation*/
varname4missingtag=mtag,/*variable name used to label the newly created variable indicating
the missing status of numeric variable in each group based on the combination of these grp_vars*/
dsdout=dsdout /*Output a new dsd*/
);
%let grp_vars4sql=%list2sql_by_grps(list=&grp_vars);
proc sql;
create table &dsdout as
select a.*,case when b.&varname4missingtag=1 then 1
                          else 0
                          end as &varname4missingtag
from &dsdin as a
left join
(select *, 1 as &varname4missingtag from &dsdin 
group by &grp_vars4sql 
having &value_var=.) as b
on 
%do gi=1 %to %ntokens(&grp_vars);
  %if &gi>1 %then %do;
		 and a.%scan(&grp_vars,&gi,%str( ))=b.%scan(&grp_vars,&gi,%str( ))
  %end;
  %else %do;
	   a.%scan(&grp_vars,&gi,%str( ))=b.%scan(&grp_vars,&gi,%str( ))
  %end;
%end;
;


%mend;

/*Demo codes:;
 data a;
input a $ b $ x;
cards;
g1 g2 .
g1 g2 2
g1 g2 1
g1 g3 2
g2 g3 1
g2 g3 2
;

*Now use macro to identify grps with missing values;
*%debug_macro;

%AddMissingTag4Grps(
dsdin=a,
grp_vars=a b, 
value_var=x,	
varname4missingtag=mtag,
dsdout=dsdout
);


*/

