%macro keep_uniq_lst(
name,/*macro variable name that will be created to include the unique elements in the input variable lst
note: for duplicates, the last element will be kept in the final macro var!*/
lst	 /*Input list containing duplicates or multiple spaces; note: spaces will be trimed!*/
);
*Need to asign the new macro var as global macro var;
*otherwise, the llast command will not work as expected, as &name can not be called outside of the macro!;
 %global &name;

 %let i1 = 1;
 %let tname =;
 %do %while (%length(%scan(&lst,&i1,%str( ))));
    %let first = %scan(&lst,&i1,%str( ));
    %let i2 = %eval(&i1 + 1);
    %do %while (%length(%scan(&lst,&i2,%str( ))));
       %let next = %scan(&lst,&i2,%str( ));
       %if %quote(&first) = %quote(&next) %then %let i2=10000;
       %else %let i2 = %eval(&i2 + 1);
    %end;
    %if (&i2<10000) %then %let tname = &tname &first;
    %let i1 = %eval(&i1 + 1);
 %end;
 %let &name = &tname;

%mend;

/*Demo codes:;
 *options mprint mlogic symbolgen;
	%keep_uniq_lst(name=new_var,lst=x y x z y);
  %put &new_var;

*/
