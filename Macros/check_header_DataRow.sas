%macro check_header_DataRow(
file,
dlm='09'x,
header_rown=1,
data_rown=2,
dsdout=header
);

data &dsdout.1;
length varname $200.;
infile "&file" dsd dlm=&dlm firstobs=&header_rown obs=&header_rown;
input varname @@;
n=_n_;
run;

proc sql noprint;
select max(n) into: tot_headers
from &dsdout.1;
quit;

data &dsdout.2;
length contents $200.;
infile "&file" dsd dlm=&dlm firstobs=&data_rown obs=&data_rown;
input contents @@;
n=_n_;
run;

proc sql noprint;
select max(n) into: tot_datacols
from &dsdout.2;
quit;

*Get number of vars in the dsd;

%if &tot_datacols ^= &tot_headers %then %do;
  %put There are different number of vars in the header and the data columns;
		%put the header has %sysfunc(left(&tot_headers)) columns, but the dsd has %sysfunc(left(&tot_datacols)) variables!;
		%put the sas macro check_header_DataRow will be terminated!;
		%abort 255;
%end;


proc sql;
create table &dsdout as 
select *
from &dsdout.2
natural join
&dsdout.1;

proc print data=&dsdout(obs=10);run;

%mend;

/*Demo:

x cd "J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\MAP3K19_Manuscript\Figures_Tables\covid19_female_vs_male_gwas_results\GTEx_Sex_Diff_Analysis";
%File_Head(filename="GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_tpm.gct",n=4);

%check_header_DataRow(
file=GTEx_Analysis_2017-06-05_v8_RNASeQCv1.1.9_gene_tpm.gct,
dlm='09'x,
header_rown=3,
data_rown=4,
dsdout=header
);

*/

