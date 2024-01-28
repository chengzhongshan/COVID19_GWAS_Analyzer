%macro allele_columns2geno(
dsd=,
cols4alleles=4-9,/*Use %bquote if containing comma among these column numbers!*/
outdsd=out
);
%pull_column(dsd=&dsd,dsdout=&outdsd,cols2pull=&cols4alleles);
*get other columns not matching with these pulled columns;
%pull_column(dsd=&dsd,dsdout=&outdsd._,cols2pull=&cols4alleles,exclude_pulled_cols=1);
data &outdsd;
length Geno $2. varname $100.;
set &outdsd;
array G{*} _numeric_;
do i=1 to dim(G) by 2;
     varname="Geno4"||vname(G{i})||"_"||strip(left(vname(G{i+1})));
		 *switch the 0 and 1 order is the first allele is 1;
		 if (G{i}>G{i+1}) then do;
					 Geno=put(G{i+1},1.)||put(G{i},1.);
		 end;
		 else do;
					 Geno=put(G{i},1.)||put(G{i+1},1.);
		 end;
		 n=_n_;
		 output;
end;
keep varname Geno n;
run;
proc sort data=&outdsd;by n;
*Note: the output dataset geno will be automatically sorted by n in the transpose process;
proc transpose data=&outdsd out=&outdsd(drop=_name_ n);
var geno;
by n;
id varname;
run;
data &outdsd;
set &outdsd._;
set &outdsd;
run;
%mend;

/*Demo codes:;

proc import datafile="C:\Users\cheng\Downloads\hapassoc\data\hypoDat.txt"
dbms=dlm out=geno_pheno replace;
delimiter=' ';
getnames=yes;
guessingrows=max;
run;


%allele_columns2geno(
dsd=geno_pheno,
cols4alleles=4-9,
outdsd=out
);



*/


