  %macro get_locuszoom_GWAS(
  gwas_num=826733, /*Go to locuszoom to search for gwas and nevigate to specific gwas and obtain its gwas number in the weblink*/
  gwasout=locus_gwas,
	use_zcat=0, /*When running it in Linux, provide value 1*/
	deleteZIP=0,/*Delete downloaded gz file after running the macro*/
	customized_infile_cmd=%str(
firstobs=2 obs=max lrecl=32767 truncover delimiter='09'x;
input chr pos rsid :$20. ref :$1. alt :$1. neg_log_p beta se AF;
p=10**(-neg_log_p);
drop neg_log_p;
) /*In cases of the gwas has different headers, it is necessary to supply customized 
	infile command for the sas macro*/
  );

%let dwnloaded_gwas_gz=%sysfunc(getoption(WORK))/locuszoom_gwas&gwas_num..gz;
filename resp "&dwnloaded_gwas_gz";
proc http 
   url="https://my.locuszoom.org/gwas/&gwas_num/data/"
   method="get"	 
   auth_basic
   out=resp 
/*   WEBUSERNAME="name"*/
/*   WEBPASSWORD="ttttttt"*/
/*   ct="application/json"*/
;
run;

/*
*For debugging when the gwas has different column names;

%ImportFileHeadersFromZIP(
zip=&dwnloaded_gwas_gz,
filename_rgx=.,
obs=2,
sasdsdout=x,
deleteZIP=0,
infile_command=%str(firstobs=1 obs=10;input;info=_infile_;),
use_zcat=0
);

%check_header_and_values(
input_dsd_or_file_or_url=x,
tgt_var_from_dsd=info,
linesep=\t,
dsdout=x_trans,
column_len=500,
header_line=1,
value_line=10,
use_zcat=0,
deleteZIP=0
);
*/

%ImportFileHeadersFromZIP(
zip=&dwnloaded_gwas_gz,
filename_rgx=.,
obs=max,
sasdsdout=&gwasout,
deleteZIP=&deleteZIP,
infile_command=&customized_infile_cmd,
use_zcat=&use_zcat
);

%mend;

/*Demo codes:;

%get_locuszoom_GWAS(
  gwas_num=826733, 
  gwasout=locus_gwas,
	use_zcat=0 
  );

*/




