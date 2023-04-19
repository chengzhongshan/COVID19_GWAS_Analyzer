%macro VCFHead (dir=,filename=,dsdout=);

filename vcf "&dir/&filename";

*Get the total number of header lines;
*The last header line is used as header in proc import;
data &dsdout;
infile vcf lrecl=32767 length=linelen;
input colnames $varying32767.linelen;
n=_n_;
colnames=_infile_;
colnames=substr(colnames,2);*Remove "#";
if substr(_infile_,1,1)^="#" then do;
   call symputx('header_num',n-1);
   stop;*No output for none "#" lines;
end;

data &dsdout;
set &dsdout;
if n=&header_num;
keep colnames;
run;

%mend;
/*
%VCFHead(dir=I:/SKCM/TCGA/Protected_Mutations/BI__IlluminaGA_DNASeq_Cont/Level_2
            ,filename=TCGA-BF-A1PU_30ba63c3-2425-434a-ae62-d4fe1479f3c0_b53844f5-2249-4ce5-9ea7-e7a0286ee5ec.oxoG.snp.capture.tcga.vcf
            ,dsdout=z);
*/
