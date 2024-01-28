%macro additive_geno2alleles(
indsd=,/*Input sas dataset containing additive genotypes, such as 0, 1, and 2*/
snp_varnames=,	 /*The order of snp varnames will be used to generate allelic columns in the same order*/
othervars2keep= ,/*Other potential pheno or covariant vars to be kept*/
sample_id=,/*varname for sample id*/
outdsd= /*output a sas dataset containing allelic columns for these snp varnames in the same order*/
);

%let keep=&snp_varnames;
%let id=id;
%let num=%ntokens(&snp_varnames);
%let tot=%eval(2*&num);

*It is confirmed that the array function will not automatically sort the snp names in the array function;
*Thus, there is no need to use the macro var snpidx4list;

      data &outdsd (keep=&id m1-m&tot &othervars2keep);
			*Keep these columns at the beginning of the table;
			retain &id &othervars2keep;

			*For debugging;
      /*data &outdsd (keep=&id snp1-snp&num m1-m&tot); */
     /*        B (drop=snp1-snp&num m1-m&tot);*/

        set &indsd;
        array snps{&num} &keep;
        array snpname{&num} snp1 - snp&num; /* this for renaming the snps */
        array ms{&tot} $1. m1 - m&tot;
				xi=1; 
        do i= 1 to dim(snps);
          snpname{xi}=snps{i};
          j =2*xi-1;
          k =2*xi;   
          if snps{i} =0 then do;
             ms{j}="0";
             ms{k}="0";
          end;
          else if snps{i}=1 then do;
            ms{j}="0";
            ms{k}="1";
          end;
          else if snps{i}=2 then do;
            ms{k}="1";
            ms{j}="1";
          end;
          else do;
            ms{k}=" ";
            ms{j}=" ";
          end;

          if snps{i} in (99, .) then snpname{i}=.;

					xi=xi+1;
        end;

        /* only keep the obs that are needed for proc haplotype */
        if sum(of snp1 - snp&num)=. then delete;
     run;


%mend;

/*Demo codes:;

data Test;
input geno_rs1887429 geno_rs17425819 id $;
cards;
0 0 S1
0 1 S2
1 0 S3
;
proc print;run;

%debug_macro;

%additive_geno2alleles(
indsd=Test,
snp_varnames=geno_rs1887429 geno_rs17425819,	
othervars2keep=,
sample_id=id,
outdsd=allelic_genos 
);
proc print data=allelic_genos;run;

*/

