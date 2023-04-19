%macro Import_VCF(dir=,filename=,dsdout=);
options compress=yes;
filename vcf "&dir/&filename";

*Get the total number of header lines;
*The last header line is used as header in proc import;
data _null_;
infile vcf lrecl=32767 length=linelen;
input header $varying32767.linelen;
n=_n_;
if substr(header,1,1)="#" then do;
   call symput('colnames',strip(substr(header,2)));
end;
if substr(header,1,1)^="#" then do;
   call symput('header_num',n);
   stop;
end;
run;
%put &header_num;
%put &colnames;

proc import datafile="&dir/&filename"
dbms=tab out=&dsdout replace;
getnames=no;
datarow=&header_num;
guessingrows=1000000;
run;

%local nvars;
%let nvars=%eval( %sysfunc(count(&colnames,%str( )))+1);
data &dsdout;
set &dsdout(rename=( 
   /*rename all the variables Var1-Varn */                                                                                                                  
	%do i = 1 %to &nvars;
      var&i=%scan(&colnames,&i)
	%end;
  )
); 
run;
options compress=no;
%mend;

/*

%Import_VCF(dir=I:/SKCM/TCGA/Protected_Mutations/BI__IlluminaGA_DNASeq_Cont/Level_2
            ,filename=TCGA-BF-A1PU_30ba63c3-2425-434a-ae62-d4fe1479f3c0_b53844f5-2249-4ce5-9ea7-e7a0286ee5ec.oxoG.snp.capture.tcga.vcf
            ,dsdout=z);

*/
