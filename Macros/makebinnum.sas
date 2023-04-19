%macro makebinnum(Range,bin_size,frmatname);
/*%let Range=2E5;*/
/*%let bin_size=1E3;*/
data for&frmatname;
retain fmtname "&frmatname" type 'n';
do i = 0 to %sysfunc(ceil(&Range/&bin_size));*Can just use ceil function without %sysfunc;
binstart = round(0 + (i*&bin_size),.1)+0.00000001;
*make the start will not overlap with the previous end;
binend = round(binstart + &bin_size, .1);
label=i+1;
output;
end;
drop i;
run;
proc format library=work cntlin=for&frmatname (rename=(binstart=start binend=end)); 
run;

%mend;

/*

data a;
do x=1 to 100;
 output;
end;
run;

%makebinnum(Range=100,bin_size=10,frmatname=dx);

data b;
set a;
b=x;
attrib b format=dx.;
run;

*/
