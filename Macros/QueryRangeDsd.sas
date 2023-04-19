%macro QueryRangeDsd(base_dsd,
                     key4range_in_base,
                     st4range_in_base,
                     end4range_in_base,
					 extra_vars_in_base2keep,
                     query_dsd,
                     key4range_in_query_dsd,
					 Pos4lookup_in_query_dsd,
                     outdsd);

/*sort the query dsd by query vars to speed up the query process;*/
					 
proc sort data=&query_dsd out=query_dsd;
by &key4range_in_query_dsd  &Pos4lookup_in_query_dsd;
run;
/*query them in base_db*/
proc sql;
create table matched_rst as
select strip(left(catx('-',a.&key4range_in_base,
                           a.&st4range_in_base,
	                       a.&end4range_in_base))) as matched_range,
       b.*

	   %if &extra_vars_in_base2keep ne %then %do;
	   %let n=1;
	   %let tot_vars=%sysfunc(countw((&extra_vars_in_base2keep,%str( ))));
	   %put there are &tot_vars extra vars to keep, which are &extra_vars_in_base2keep;
	   %do %while (%scan(&extra_vars_in_base2keep,&n,%str( )) ne);
	      %let var=%scan(&extra_vars_in_base2keep,&n,%str( ));
		  %let n=%eval(&n+1);
           %str(,) a.&var
	   %end;
	   %end;

from &base_dsd as a,
     query_dsd as b
where a.&key4range_in_base=b.&key4range_in_query_dsd and
      b.&Pos4lookup_in_query_dsd between a.&st4range_in_base and a.&end4range_in_base;

create table &outdsd as
select a.*,b.matched_range

	   %if &extra_vars_in_base2keep ne %then %do;
	   %let n=1;
	   %let tot_vars=%sysfunc(countw((&extra_vars_in_base2keep,%str( ))));
	   %put there are &tot_vars extra vars to keep, which are &extra_vars_in_base2keep;
	   %do %while (%scan(&extra_vars_in_base2keep,&n,%str( )) ne);
	      %let var=%scan(&extra_vars_in_base2keep,&n,%str( ));
		  %let n=%eval(&n+1);
           %str(,) b.&var
	   %end;
	   %end;

from query_dsd as a
left join
matched_rst as b
on a.&key4range_in_query_dsd=b.&key4range_in_query_dsd and
   a.&Pos4lookup_in_query_dsd=b.&Pos4lookup_in_query_dsd;

   

%mend;

/*

data base;
input chr $ st end label1 $ label2 $;
cards;
1 100 20000 yy xx
2 200 30000 zz ww
;
data query;
input chromosome $ BP;
cards;
1 500
2 30
4 20
;
run;

*options mprint mlogic symbolgen;

*make sure the key4range_in_base and key4range_in_query_dsd are the same type;
*which will be used to test equality in where condition;

*It will not keep extra vars in base;
%QueryRangeDsd(base_dsd=base,
                     key4range_in_base=chr,
                     st4range_in_base=st,
                     end4range_in_base=end,
					 extra_vars_in_base2keep=,
                     query_dsd=query,
                     key4range_in_query_dsd=chromosome,
					 Pos4lookup_in_query_dsd=BP,
                     outdsd=result);
*It will keep extra vars in base;
%QueryRangeDsd(base_dsd=base,
                     key4range_in_base=chr,
                     st4range_in_base=st,
                     end4range_in_base=end,
					 extra_vars_in_base2keep=label1 label2,
                     query_dsd=query,
                     key4range_in_query_dsd=chromosome,
					 Pos4lookup_in_query_dsd=BP,
                     outdsd=result);

*/

