%macro range2consecutive_num(arg,step);
%let consect_range=;
/*  make sure range in the format: 0-10 20-300;*/
%let n=1;
%do %until (%qscan(&arg,%eval(&n),%str( ))=%str()); 
   %let range=%qscan(&arg,%eval(&n),%str( ));
   %let st=%qscan(&range,1,%str(-));
   %let end=%qscan(&range,2,%str(-));
   %do i=&st %to &end %by &step;
         %let consect_range=&consect_range &i;
	%end;
    %let n=%eval(&n+1);
%end;
&consect_range
%put &&consect_range;
%mend range2consecutive_num;

/*
options mprint mlogic symbolgen;

%macro xx;
%let x=%range2consecutive_num(arg=0-10 20-300,step=10);
%put &x;
%mend;

%xx;

*/


