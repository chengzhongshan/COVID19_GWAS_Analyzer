%macro UniqNumGeno4VCFsamples(
/*Focus on SNPs that have different genotype in the current sample by comparing the genotype with other samples;
Also request the genotype to be het or homo for the alternative allele;
Additionally require the numeric genotype > other samples genotypes;
tmp=tmp+(G{ii}^=G{xi})*(G{ii}>0)*(G{ii}>G{xi});
However, the following more strict rules are used by the current macro:
genotype = 2 or 1 and all other genotypes are 0;
*/
vcf_file=,
first_num_samples=,/*If left empty, the total number of samples will be used by the macro
for the vcf to calculate unique snps among these first number of samples!*/
dsd4uniqnumofsnps=snpsummary,
snpinfo_dsd=snpinfo /*For passed unique SNPs, output SNP info, such as chr, pos, ref, and alt*/
);

*Get the total number of header lines;
%Header4VCF(
vcf_file=&vcf_file,
global_header_num=vcf_header_num,
global_colnames=vcf_colnames,
global_vcfcolnums=vcfcolnums
);

filename g "&vcf_file";

%if %length(&first_num_samples)=0 %then %do;
    %let numofsample=%sysevalf(&vcfcolnums-9);
%end;
%else %do;
    %let numofsample=&first_num_samples;
	%let vcfcolnums=%sysevalf(9+&numofsample);
%end;

data x;
infile g dsd truncover dlm='09'x firstobs=1 obs=max;
length x1-x&vcfcolnums $20. chr $5. ref $1. alt $1.;
array G{&numofsample} g1-g&numofsample;
array GT{&numofsample} $ x10-x&vcfcolnums;
array ET{&numofsample} E1-E&numofsample;
input @;
if not prxmatch("/^#/",_infile_) then do;
/*  input x1 :$8. x2 :$8. x3 :$8. x4 :$8. x5 :$8. x6 :$8. x7 :$8.;*/
  input x1-x&vcfcolnums :$20.;
  do i=1 to dim(GT);
		 G{i}=scan(GT{i},1,'|')+scan(GT{i},2,'|')+0;
  end;
  do ii=1 to dim(G);
     tmp=0;
	 do xi=1 to dim(G);
	    if ii^=xi then do;
		    *Focus on SNPs that have different genotype in the current sample by comparing the genotype with other samples;
		    *Also request the genotype to be het or homo for the alternative allele;
		    *Additionally require the numeric genotype > other samples genotypes;

			*tmp=tmp+(G{ii}^=G{xi})*(G{ii}>0)*(G{ii}>G{xi});

			*Alteration 1: genotype = 2 or 1 and all other genotypes are 0;
			tmp=tmp+(G{ii}>=1)*(G{xi}=0);
		end;
		ET{ii}=tmp=&numofsample-1;
	 end;
  end;

  *Also output chr, pos, and ref, alt;
  chr=x1;pos=x2+0;
  ref=x4;alt=x5;

  output;
end;
drop x: i xi ii tmp g:;
run;

filename g clear;

proc summary data=x sum;
var _numeric_;
output out=&dsd4uniqnumofsnps sum=sum1-sum&numofsample;
run;

%select_element_range_from_list( 
list=&vcf_colnames, 
st=10, 
end=, 
sublist=newlist, 
sep=%str( ) 
); 
%put Target samples in the VCF are: &newlist; 

%local si samplevarlist;
%let samplevarlist=sum1;
%let samplevarlist1=E1;
%do si=2 %to &numofsample;
  %let samplevarlist=&samplevarlist sum&si;
  %let samplevarlist1=&samplevarlist1 E&si;
%end;

data &dsd4uniqnumofsnps ; 
set &dsd4uniqnumofsnps; 
%Rename_oldvarlist2newvarlist(&samplevarlist, &newlist); 
drop _type_;
rename _freq_=total_snps;
run; 

data x;
set x;
if sum(of E1-E&numofsample) =1;
data x;
set x;
%Rename_oldvarlist2newvarlist(&samplevarlist1, &newlist); 
run;

proc datasets ;
change x=&snpinfo_dsd;
run;

%mend;

/*Demo codes:;

x cd "E:\scASE\data\1000G_hg38";
%debug_macro;
%UniqNumGeno4VCFsamples(
vcf_file=tgt_chr1_22.vcf,
first_num_samples=2,
dsd4uniqnumofsnps=snpsummary_for_2_samples
);

%UniqNumGeno4VCFsamples(
vcf_file=tgt_chr1_22.vcf,
first_num_samples=4,
dsd4uniqnumofsnps=snpsummary_for_4_samples
);

%UniqNumGeno4VCFsamples(
vcf_file=tgt_chr1_22.vcf,
first_num_samples=6,
dsd4uniqnumofsnps=snpsummary_for_6_samples
);

%UniqNumGeno4VCFsamples(
vcf_file=tgt_chr1_22.vcf,
first_num_samples=8,
dsd4uniqnumofsnps=snpsummary_for_8_samples
);

%UniqNumGeno4VCFsamples(
vcf_file=tgt_chr1_22.vcf,
first_num_samples=,
dsd4uniqnumofsnps=snpsummary_for_10_samples,
snpinfo_dsd=snpinfo
);
%ds2csv(data=snpinfo,
csvfile=E:\scASE\data\1000G_hg38\uniqsnpinfo.csv,
runmode=b);


%union_add_tags(dsds=
Snpsummary_for_2_samples
Snpsummary_for_4_samples
Snpsummary_for_6_samples
Snpsummary_for_8_samples
Snpsummary_for_10_samples, 
out=CombinedUniqNumSNPs); 

%ds2csv(data=CombinedUniqNumSNPs,
csvfile=E:\scASE\data\1000G_hg38\CombinedUniqNumSNPs.csv,
runmode=b);


*/



