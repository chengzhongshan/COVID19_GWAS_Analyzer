%macro make_dbsnp_db(
dbsnp_fullpath,
outlib_path,
outdsd
);

libname O "&outlib_path";

%File_Head(filename="&dbsnp_fullpath",n=10);

%ImportFilebyScanAtSpecCols(file=&dbsnp_fullpath
                 ,dsdout=O.&outdsd
                 ,firstobs=1
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
				 ,SpeColNums=2 3 4 5 10
);


data O.&outdsd;
set O.&outdsd;
if upcase(chrom)="CHRX" then chrom="chr23";
if upcase(chrom)="CHRY" then chrom="chr24";
chrom=scan(chrom,1,'chr');
run;

%char2num_dsd(dsdin=O.&outdsd,
              vars=chrom chromstart chromend,
              dsdout=O.&outdsd);

proc datasets lib=O nolist;
modify &outdsd;
rename chrom=chr chromstart=st chromend=end;
index create chr_st=(chr st);
run;

libname O clear;
%mend;

/*
%make_dbsnp_db(
dbsnp_fullpath=H:\WGS_SNPs\snp151\snp151,
outlib_path=H:\WGS_SNPs,
outdsd=dbsnp151
);
*/

