%macro ApplyFunc_rowwide(dsdin
                         ,row_keys
						 ,KeyVar4dsdout
                         ,Regex4col_vars2apply
						 ,SQL_Fun4apply
                         ,dsdout
						 ,KeyVar4dsdout_length=200
                         ,AlsoAppFun4Cols=0);
%let n=%numargs(&row_keys);
%put macro var row_keys are &row_keys;

%if %eval(&n=0) %then %do;
data &dsdout;
set &dsdin;
&KeyVar4dsdout="AllRows";
run;
%end;
%else %do;
data &dsdout;
length &KeyVar4dsdout $ &KeyVar4dsdout_length;
set &dsdin;
&KeyVar4dsdout=catx(":",
%let i=1;
%do %while (&i<&n);
   %scan(&row_keys,&i,%str( )),
   %let i=%eval(&i+1);
%end;
   %scan(&row_keys,&n,%str( ))
);
run;
%end;


proc contents data=&dsdin out=_vars_ noprint;
run;
proc sql noprint;
select Name into: vars4apply separated by ' '
from _vars_
where prxmatch("/&Regex4col_vars2apply/i",Name);

select count(Name) into: nvars4apply
from _vars_
where prxmatch("/&Regex4col_vars2apply/i",Name);


%if %eval(&AlsoAppFun4Cols=0) %then %do;
proc sql;
create table &dsdout as
select &KeyVar4dsdout,
  %let ii=1;
  %do %while (&ii<&nvars4apply);
   %let Var=%scan(&vars4apply,&ii,%str( ));
   %str(&SQL_Fun4apply(&Var) as New_&Var,)
   %let ii=%eval(&ii+1);
  %end;
   %let Var=%scan(&vars4apply,&ii,%str( ));
   %str(&SQL_Fun4apply(&Var) as New_&Var)
from &dsdout 
group by &KeyVar4dsdout
order by &KeyVar4dsdout;
%end;

%else %if %eval(&AlsoAppFun4Cols=1) %then %do;
proc sql;
create table &dsdout as
select &KeyVar4dsdout,
  %let ii=1;
  %let Var=&SQL_Fun4apply(;
  %do %while (&ii<&nvars4apply);
   %let Var=&Var%scan(&vars4apply,&ii,%str( )),;
   %let ii=%eval(&ii+1);
  %end;
   %let Var=&Var%scan(&vars4apply,&ii,%str( ));
   %str(&Var%) as ALL_Matched_Cols)
from &dsdout 
group by &KeyVar4dsdout
order by &KeyVar4dsdout;

/*Assemble all dup &KeyVar4dsdout for &SQL_Fun4apply*/
proc sql;
create table &dsdout as
select &KeyVar4dsdout,&SQL_Fun4apply(All_Matched_Cols) as &SQL_Fun4apply
from &dsdout
group by &KeyVar4dsdout;

%end;

*Only remove 'New_' within varnames;
%Rename_Del_Rgx4All_Vars(indsd=work.&dsdout,Rgx=New_);

%mend;

/*
data a;
input key $ a bb;
cards;
a 1 0
a 2 1
b 1 2
b 1 4
c 1 5
;
options mprint mlogic symbolgen;

*Note: Regex4col_var2apply will search for query string insensitively for case;
*Note: KeyVar4dsdout will try to catx all row_keys with ':';

*ApplyFunc_rowwide for avg,std,sum,median,max,min, or other related functions.
*If use mean and AlsoAppFun4Cols=0, make sure to use avg to replace mean;
%ApplyFunc_rowwide(dsdin=a
                  ,row_keys=key
                  ,KeyVar4dsdout=OutKeyVar
                  ,Regex4col_vars2apply=[ab]
				  ,SQL_Fun4apply=max
                  ,dsdout=t
                  ,KeyVar4dsdout_length=200
                  ,AlsoAppFun4Cols=0);

*If row_keys is missing, will apply specific function on all rows for each column;
%ApplyFunc_rowwide(dsdin=a
                  ,row_keys=
                  ,KeyVar4dsdout=OutKeyVar
                  ,Regex4col_vars2apply=[ab]
				  ,SQL_Fun4apply=max
                  ,dsdout=t
                  ,KeyVar4dsdout_length=200
                  ,AlsoAppFun4Cols=0);

*If AlsoAppFun4Cols=1, will apply specific function on each row or ALL Rows (if row_keys is missing) for ALL these matched columns;
*For AlsoAppFun4Cols=1, we can not use avg but mean, because avg is going to calculate mean based on group and mean is to calculate mean of different columns;
*Should be careful to use this function to calculate mean of ALL data points.
%ApplyFunc_rowwide(dsdin=a
                  ,row_keys=
                  ,KeyVar4dsdout=OutKeyVar
                  ,Regex4col_vars2apply=[ab]
				  ,SQL_Fun4apply=mean
                  ,dsdout=t
                  ,KeyVar4dsdout_length=200
                  ,AlsoAppFun4Cols=1);

*/
