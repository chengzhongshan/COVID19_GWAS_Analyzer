%macro GetNumGeno4VCF(
vcf_file=,
dsdout=NumGeno
);

*Get the total number of header lines;
%Header4VCF(
vcf_file=&vcf_file,
global_header_num=vcf_header_num,
global_colnames=vcf_colnames,
global_vcfcolnums=vcfcolnums
);

filename g "&vcf_file";

%let numofsample=%sysevalf(&vcfcolnums-9);

data &dsdout (drop=x: i);
infile g dsd truncover dlm='09'x firstobs=1 obs=max;
length x1-x&vcfcolnums $20. chr $4. ref $1.;
array G{&numofsample} g1-g&numofsample;
array GT{&numofsample} $ x10-x&vcfcolnums;
input @;
if not prxmatch("/^#/",_infile_) then do;
/*  input x1 :$8. x2 :$8. x3 :$8. x4 :$8. x5 :$8. x6 :$8. x7 :$8.;*/
  input x1-x&vcfcolnums :$20.;
  do i=1 to dim(GT);
		 G{i}=scan(GT{i},1,'|')+scan(GT{i},2,'|')+0;
  end;
  chr=x1;pos=x2+0;
  ref=x4;
  output;
end;
run;

filename g clear;

%select_element_range_from_list( 
list=&vcf_colnames, 
st=10, 
end=, 
sublist=newlist, 
sep=%str( ) 
); 
%put Target samples in the VCF are: &newlist; 

%local si samplevarlist;
%let samplevarlist=g1;
%do si=2 %to &numofsample;
  %let samplevarlist=&samplevarlist g&si;
%end;

data &dsdout ; 
set &dsdout; 
%Rename_oldvarlist2newvarlist(&samplevarlist, &newlist); 
run; 


%mend;

/*Demo codes:;

x cd "E:\scASE\data\1000G_hg38";

%GetNumGeno4VCF(
vcf_file=tgt.vcf,
dsdout=snpsummary
);

*/



