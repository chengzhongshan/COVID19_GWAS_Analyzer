%macro xls2txt(xlspath,getnames,txtoutpath);
proc import datafile="&xlspath" dbms=excel out=xlstmp replace;
getnames=&getnames;
run;
proc export data=xlstmp dbms=tab outfile="&txtoutpath" replace;
run;
%mend;

/*

%xls2txt(
xlspath=C:\Users\zcheng\Documents\PROPEL_SV_SNV_Testing\SNV Caller evaluation\ConsensueMuts\SJALL048347_D1_G1\SJALL048347_D1_G1.Consensus.xlsx,
getnames=yes,
txtoutpath=C:\Users\zcheng\Documents\PROPEL_SV_SNV_Testing\SNV Caller evaluation\ConsensueMuts\SJALL048347_D1_G1\tmp.txt
);

*/




