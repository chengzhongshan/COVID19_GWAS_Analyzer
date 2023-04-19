%macro import_multi_xls(xlsdsd,getnames);
data _null_;
set &xlsdsd;
outpath=prxchange("s/[^\.]+$/txt/",-1,filefullname);
rc=dosubl('%xls2txt(xlspath='||filefullname||','||"getnames=&getnames,"||'txtoutpath='||outpath||')');
run;
%mend;

/*

%let path=C:\Users\zcheng\Documents\PROPEL_SV_SNV_Testing\SNVCallerevaluation\ConsensueMuts;

%RecSearchFiles2dsd(
root_path=&path,
filter=Consensus.xlsx,                                   
perlfuncpath=Z:\ResearchHome\ClusterHome\zcheng\SAS-Useful-Codes,
outdsd=Out);

%import_multi_xls(xlsdsd=out,
                  getnames=yes);

*/
