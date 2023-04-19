
%macro SplitDsdIntoMultiDsdsByNumGrp(dsd,numgrpvar,newdsd_prefix);
  %local grp_var_list ii;
  proc sql noprint;
  select distinct &numgrpvar into: grp_var_list separated by ' '
  from &dsd;
  %put group vars: &grp_var_list;
  *Do not use macro var i here, as it was used by Rename_Add_Prefix4All_Vars;
  *Which will reset the macro var i as 1 after running it!;
  %let ii=1;
  %do %while (%scan(&grp_var_list,&ii,%str( )) ne);
        %let var=%scan(&grp_var_list,&ii,%str( ));
		data &newdsd_prefix.&ii;
		set &dsd;
		where &numgrpvar=&var;
		run;
		*This macro will use macro var i, after it completes, the macro var i will be 1;
		*correct this by using local macro var i in the following macro;
		%Rename_Add_Prefix4All_Vars(indsd=work.&newdsd_prefix.&ii,prefix=grp&ii);
		%let ii=%eval(&ii+1);
  %end;
%mend;

/*
data a;
input a b c;
cards;
1 2 3
4 5 6
1 2 4
1 2 3
4 5 6
1 2 4
0 0 0
1 1 1
2 3 4
0 2 3
;
run;
options mprint mlogic symbolgen;
%SplitDsdIntoMultiDsdsByNumGrp(dsd=a,numgrpvar=c,newdsd_prefix=xxxx);
*/
