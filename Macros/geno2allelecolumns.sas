%macro geno2allelecolumns(
dsd=,
cols4genos=,/*such as 4-9 or %bquote(4-7,8); Use %bquote if containing comma among these column numbers!*/
outdsd=out
);
%pull_column(dsd=&dsd,dsdout=&outdsd,cols2pull=&cols4genos);
*get other columns not matching with these pulled columns;
%pull_column(dsd=&dsd,dsdout=&outdsd._,cols2pull=&cols4genos,exclude_pulled_cols=1);

data &outdsd;
set &outdsd;
array G{*} $2. _character_;
do i=1 to dim(G);
     *It is important to add the allele appendex but not prefix to keep the two alleles close to each other in the final output table;
     v=strip(left(vname(G{i})))||"_A1";
		 allelenum=1;
		 n=_n_;
		 allele=substr(G{i},1,1)+0;
		 output;
		 allelenum=2;
		 v=strip(left(vname(G{i})))||"_A2";
		 allele=substr(G{i},2,1)+0;
		 output;
end;
keep v allele n;
run;

proc sort data=&outdsd;by n v;run;


*Note: the output dataset geno will be automatically sorted by n in the transpose process;
proc transpose data=&outdsd out=&outdsd(drop=_name_ n);
var allele;
id v;
by n;
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

*Now change these genos to allelic columns again;
*%debug_macro;
%geno2allelecolumns(
dsd=out,
cols4genos=4-6,
outdsd=out_new
);
*/


