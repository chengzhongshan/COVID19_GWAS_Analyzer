%macro Bed2SAS_DB(Bed_Dir,Regex4bed,Libname4out,outdsd);
%ImportAllFilesInDirbyScan(filedir=&Bed_Dir
                 ,fileRegexp=&Regex4bed
                 ,dsdout=reg_dsd
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
		         ,notverbose=1
                 ,debug=0
);
options compress=yes;
data &Libname4out..&outdsd (where=(chr^=.) keep=st end chr memname);
set reg_dsd;
if (V1="chrX" or V1="chr23") then chr=23;
else if (V1="chrY" or V1="chr24") then chr=24;
else chr=put(prxchange('s/chr//',-1,V1),2.);
st=V2+0;
end=V3+0;
memname=prxchange('s/.bed//',-1,memname);
run;

proc sort data=&Libname4out..&outdsd;
by chr st end;
run;
proc datasets lib=&Libname4out nolist;
modify &outdsd;
index create chr_st_end=(chr st end);
run;
options compress=no;
%mend;
/*

libname BED "D:\F_tmp\NewTCGAAssocRst\VAF_SAS";

*bed filename (memname) will be included in the outdsd;

%Bed2SAS_DB(Bed_Dir=D:\NGS_lib\Linux_codes_SAM\WGS_Analysis\annotate_vars\overlap,
            Regex4bed=bed,
            Libname4out=BED,
            outdsd=Features19);


*/

