%macro Header4VCF(
vcf_file=,
/*Create three global macro vars for using by other codes*/
global_header_num=vcf_header_num,
global_colnames=vcf_colnames,
global_vcfcolnums=vcfcolnums
);
filename vcf "&vcf_file";
%global &global_header_num &global_colnames &global_vcfcolnums;

*Reset values of these global macro vars;
%let  &global_header_num=;
%let &global_colnames=;
%let &global_vcfcolnums=;

*Get the total number of header lines;
*The last header line is used as header in proc import;
data _null_;
infile vcf lrecl=32767 length=linelen;
input header $varying32767.linelen;
n=_n_;
if substr(header,1,1)="#" then do;
   call symput("&global_colnames",strip(substr(header,2)));
end;
if substr(header,1,1)^="#" then do;
   call symput("&global_header_num",n);

   colnums=countc(header,'09'x);
   if colnums>0 then do;
      colnums=colnums+1;
   end;
   else do;
	 colnums=1;
   end;
   call symputx("&global_vcfcolnums",colnums);
   stop;
end;
run;
filename vcf clear;

%put The value of VCF header global macro var &global_header_num.:;
%put &&&global_header_num;

%put The value of VCF header global macro var &global_colnames.:;
%put &&&global_colnames;

%put The value of VCF header global macro var &global_vcfcolnums.:;
%put &&&global_vcfcolnums;

%mend;

/*Demo codes:;
x cd "E:\scASE\data\1000G_hg38";

%Header4VCF(
vcf_file=tgt.vcf,
global_header_num=vcf_header_num,
global_colnames=vcf_colnames,
global_vcfcolnums=vcfcolnums
);

*/
