%macro makebins(Range,bin_size,frmatname);
/*%let Range=2E5;*/
/*%let bin_size=1E3;*/
data for&frmatname;
drop i;
retain fmtname "&frmatname" type 'n';
do i = 0 to %sysfunc(ceil(2*&Range/&bin_size));*Can just use ceil function without %sysfunc;
binstart = round(-&Range + (i*&bin_size),.1);
binend = round(binstart + &bin_size, .1);
label = cat(binstart,"  to  ", binend);
*make the start will not overlap with the previous end;
binend=binend-0.00001;
output;
end;
run;
proc format library=work cntlin=for&frmatname (rename=(binstart=start binend=end)); 
run;

%mend;

/*

%makebins(Range=2e5,bin_size=1e3,frmatname=dx);

*/
