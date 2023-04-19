%macro make_bin_format(bins,out_format_name);

%let i=1;
%let bin=%scan(&bins,&i,%str(' '));
%let i=2;
%let format_string=%sysfunc(cat(low-,&bin-0.0000001)) = "low<&bin";
%put &format_string;
%do %while (%scan(&bins,&i,%str(' ')) ne );
   %let lagbin=%scan(&bins,%eval(&i-1),%str(' '));
   %let bin=%scan(&bins,&i,%str(' '));
   %let tmp_bin=%sysfunc(cat(&lagbin,-,&bin)) = "&lagbin-&bin";
   %let format_string=&format_string &tmp_bin;
 %let i=%eval(&i+1);
%end;
%put &format_string;

proc format;
value &out_format_name &format_string
			other='unknown';

%mend;
/*
options mprint mlogic symbolgen;
*pay attention to olds select none in the macro;
%make_bin_format(bins=10 20 30 40 50 60 70 80 90 100,out_format_name=frt);

*Note: for proc MEANS and othe procedure to use the new format;
*It is necessary to run the following code:
data x;
set x;
new_char_var=put(var,frt.);
run;

*/
