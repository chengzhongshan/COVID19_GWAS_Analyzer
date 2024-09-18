%macro make_bin_format(
bins,/*space separated list, such as 10 20 30 500 or 10..100 500..100; ensure the consecutive numbers use the linker ".."*/
steps,/*space separated steps for these consecutive nums; if there are less number of steps provided compared to the consecutive numbers
included in the bins, the macro will use the last steps to split the consecutive numbers that do not have matched steps in the order!*/
out_format_name,
bindsdout=bingrpnames, /*The output dataset contains a numberic var to sort the formated bin name, 
which can be used to sort other dataset that is formated by the bin name by the numeric order*/
smallest_value=0 /*The smallest value to enable the Lower_than_1stBin included in the output bindsdout*/
);

%let bins=%range2consecutive_num(arg=&bins,step=&steps,linker4consecutivenum=%str(\.\.));

%let i=1;
%let bin=%scan(&bins,&i,%str(' '));
%let i=2;
%let format_string=%sysfunc(cat(low-,&bin-0.0000001))="Lower_then_&bin";
%do %while (%scan(&bins,&i,%str(' ')) ne );
   %let lagbin=%scan(&bins,%eval(&i-1),%str(' '));
   %let bin=%scan(&bins,&i,%str(' '));
   %let tmp_bin=%sysfunc(cat(&lagbin,-,&bin))="&lagbin._&bin";
   %let format_string=&format_string &tmp_bin;
 %let i=%eval(&i+1);
%end;
%put Your formated bins are as follows:;
%let format_string=&format_string %nrbquote(&bin-high="Higher_than_&bin");
%do fi=1 %to %eval(&i-1);
   %put %scan(&format_string,&fi,%str( ));
%end;

proc format;
value &out_format_name %unquote(&format_string);

*Also generate a data set to keep the rank of these bins;
%rank4grps(
    grps=&smallest_value &bins,
    dsdout=&bindsdout
  );
data &bindsdout;
set &bindsdout;
bingrps=put(input(grps,best32.)+0.0000001,&out_format_name..);
run;  
%mend;
/*
options mprint mlogic symbolgen;
*pay attention to olds select none in the macro;
*%debug_macro;
%make_bin_format(bins=10..100 200 1000..10000,steps=10 1000,out_format_name=frt);

*Note: for proc MEANS and othe procedure to use the new format;
*It is necessary to run the following code:;
data x;
set x;
new_char_var=put(var,frt.);
run;


*/
