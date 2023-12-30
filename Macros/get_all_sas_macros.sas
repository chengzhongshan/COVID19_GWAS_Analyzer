%macro get_all_sas_macros(
macro_dir=H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
outdsd=files
);
%RecSearchFilesPureSAS(
root_path=&macro_dir,
filter=\.sas,
outdsd=files
);
data &outdsd;
set &outdsd;
macro=prxchange("s/.*Macros\/([^\/]+\.sas)/$1/i",-1,filefullname);
if prxmatch('/\//',macro) then delete;
run;
%mend;

/*Demo codes:;

%get_all_sas_macros(
macro_dir=H:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
outdsd=files
);

*/
