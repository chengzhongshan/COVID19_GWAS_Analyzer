%macro InitEstHapFrq(
gen_pheno_sasdsd=,
/*The input sas dataset should be in the following format:
ID pheno cov1 snpA1 snpA2 snpB1 snpB2 snpC1 snpC2;
with two alleles represented by 0 and 1 and the order of allele1 and allele2 should be strictly put in the order of 0 and 1;
*/
Hapfrq_outdsd=Hapfrq, 
/*Initially estimated haplotype frquencies and its corresponding haplotypes coded by 0 and 1;
Note: the order of these haplotypes are according to the haplotypes in the first colums of haplotypes in the
following output dataset HapDM_outdsd*/
HapDM_outdsd=HapDM_matrix,
/*Estimated non-zero dummy haplotypes along with original ID and phenos, covariant, a constant column, numberic ID, weight*/
numSNPsInDsd=3,/*The total number of snps included in the sas dataset gen_pheno_sasdsd;*/
maxMissingGenos=1, /*Maximum number of missing genotypes allowed for a ID; otherwise the sample will be excluded*/
verbose=1	 /*Print additional information for detailed processing of the data in iml*/
);

proc iml;
start makeHaploLabN(x, numSNPs);
    len = ncol(x);
    ans = j(len, numSNPs, 0);
    do _i_=1 to len;
     _x_=x[_i_];
     do i = (numSNPs-1) to 0 by -1;
         digit = floor(_x_ / (2 ** i));
         ans[_i_, numSNPs - i] = digit;
         _x_ = _x_ - digit * (2 ** i);
     end;
   end;
return(ans);
finish;

/*/*Examination codes:*/*/
/*numSNPs=3;*/
/*seq=0:(2**numSNPs-1);*/
/*haploLabs=makeHaploLabN(seq,numSNPs);*/
/*print haploLabs;*/;

start getHaplos(SNProw, heteroVec);																																	                                                                                                                                                                                                                  
    /* Determine haplotypes consistent with observed genotypes */
    numSNPs = ncol(SNProw)/2;
    heteroCount = sum(heteroVec);
    homoCount = numSNPs - heteroCount;
    
	if heteroCount=0 then do;
		*Only one haplotype when all snps are homozygous;
	   haploCombos = j(1, 2*numSNPs, .);
		     do i = 1 to numSNPs;
            haploCombos[1, i] = SNProw[2*i];
						haploCombos[1, i+numSNPs] = SNProw[2*i-1];
        end;
	end;

	else do;
    /* Create matrix to store haplotype combinations */
		*Ensure to have 2**(heteroCount-1) for half of the targeted haplotypes;
		*Also, there would be 2*numSNPs columns;
    haploCombos = j(2**(heteroCount-1), 2*numSNPs, .);
    haploIdx = 1;
    
    /* Create matrix to store heterozygous SNP indices */
    hetIdxMat = j(1, heteroCount, .);
    hetIdx = 1;
    
    /* Loop through SNPs to identify heterozygous SNPs and their indices */
    do i = 1 to numSNPs;
        if heteroVec[i] = 1 then do;
            hetIdxMat[hetIdx] = i;
            hetIdx = hetIdx + 1;
        end;
        else do;
            haploCombos[, i] = SNProw[2*i];
						haploCombos[, i+numSNPs] = SNProw[2*i-1];
        end;
    end;
    

    /* Generate haplotype combinations */
		*For the 1st het SNP, all half haplotypes, including the left hap1 and the right hap2, at the site will be 1 or 0;
		haploCombos[, hetIdxMat[1]] = 1;
    haploCombos[, numSNPs+hetIdxMat[1]] = 0;
/*		print haploCombos;*/

		do j=1 to 2**(heteroCount-1);
        hetBin = reverse(putn(j - 1, 'binary32.'));
/*				print hetBin;*/
        hetBin=cshape(hetBin,1,nleng(hetBin),1);
			 if heteroCount>1  then do;
				do jj=2 to heteroCount;
						 haploCombos[j, hetIdxMat[jj]] = num(hetBin[jj-1]);
             haploCombos[j, numSNPs+hetIdxMat[jj]] = 1-num(hetBin[jj-1]);
				end;
			 end;
    end;
	end;

  return haploCombos;

finish;


start isHetero(SNProw, numSNPs);
    /* Identify heterozygous SNPs in a genotype vector */
    hetVec = j(1, numSNPs, 0);
    
    do i = 1 to numSNPs;
 /*       This is only applicable to the input with the format of snpA1A2 snpB1B2 snpC1C2*/
/*        if substr(SNProw[i], 1, 1) ^= substr(SNProw[i], 2, 2) then do;*/
		/*SNProw format should be like this: snpA1 snpA2 snpB1 snpB2 snpC1 snpC2 .....*/
		 if SNProw[2*i] ^= SNProw[2*i-1] then do;
            hetVec[i] = 1;
        end;
    end;
    
    return hetVec;
finish;
/*Example codes*/
/*SNPdat={1 0 1 1 1 1};*/
/*SNProw=SNPdat[1,];*/
/*numSNPs=3;*/
/*hetrst=isHetero(SNProw,numSNPs);*/
/*print hetrst;*/
/**/

start handleMissings(SNPdat, nonSNPdat, numSNPs, maxMissingGenos);
    /* Identify and handle missing data */
    missIdx = loc(SNPdat = .);
    numMiss = nrow(missIdx);
    ID=1:nrow(SNPdat);
    ID=ID`;;
    if numMiss > 0 then do;
        /* Determine number of heterozygotes for each SNP with missing data */
        do i = 1 to numMiss;
            snpIdx = missIdx[i, 2];
            hetVec = isHetero(SNPdat[missIdx[i, 1], ], numSNPs);
            hetSnp = hetVec[snpIdx];
            hetCount = sum(hetVec);
            
            if hetSnp = 1 then do;
                /* Missing genotype is heterozygous */
                SNPdat[missIdx[i, 1], snpIdx] = round(ranuni(12345), 0);
            end;
            else do;
                /* Missing genotype is homozygous */
                SNPdat[missIdx[i, 1], snpIdx] = hetCount / (2 * (numSNPs - 1));
            end;
        end;
    end;
    
    /* Check for individuals with too many missing genotypes */
		*https://blogs.sas.com/content/iml/2015/06/01/functions-on-columns.html;
    indMissCount_ids = (SNPdat = .);
		indMissCount=	indMissCount_ids[,+];
    badInd = loc(indMissCount > maxMissingGenos);
    
    if nrow(badInd) > 0 then do;
        print "Individuals with too many missing genotypes have been identified and will be removed";
        
        SNPdat = SNPdat[setdif(1:nrow(SNPdat),badInd), ];
        nonSNPdat = nonSNPdat[setdif(1:nrow(nonSNPdat), badInd), ];
        ID = ID[setdif(1:nrow(ID),badInd)];
    end;
    
    return ID || SNPdat || nonSNPdat;
finish;


/*Example codes;*/
/*SNPdat={1 1 0 1 0 1,*/
/*                  0 1 0 1 0 1};*/
/*nonSNPdat={1 2,*/
/*                        0 2};*/
/*numSNPs=3;*/
/*maxMissingGenos=1;*/
/*preProcDat = handleMissings(SNPdat, nonSNPdat, numSNPs, maxMissingGenos);*/
/*print preProcDat;*/
/**/
/*codeHaploDM<-function(haplos,haploLabs){*/
/**/
/*  n=length(haplos)*/
/*  nsnp=ncol(haploLabs)*/
/**/
/*  ans1<-t(haplos[1:(n/2)]==t(haploLabs))*/
/*  ans2<-t(haplos[(n/2+1):n]==t(haploLabs))*/
/*  ans11<-ans1[,1]*/
/*  ans22<-ans2[,1]*/
/*  for(i in 2:nsnp) {*/
/*	ans11<-ans11&ans1[,i]*/
/*	ans22<-ans22&ans2[,i]*/
/*  }*/
/*  ans=ans11+ans22*/
/**/
/*  return(ans)*/
/*}*/;

start codeHaploDM(combhaplos, haploLabs);
    /* Create a design matrix row corresponding to the haplotype vector */
	n=ncol(combhaplos);
  nsnp=ncol(haploLabs);

  ans1= t(combhaplos[1:(n/2)]=t(haploLabs)) ;
  ans2 = t(combhaplos[(n/2+1):n]=t(haploLabs)) ;
  ans11=ans1[,1];
  ans22=ans2[,1];
  do i = 2 to nsnp;
	ans11=ans11 & ans1[,i];
	ans22=ans22 & ans2[,i];
 end;
  ans=ans11+ans22;

  return(ans);

finish;
/*/*Example codes*/*/
/*numSNPs=3;*/
/*heteroVec={0 0 1};*/
/*SNPdat={1 1 0 0 0 1};*/
/**Possible haplotypes;*/
/**S1=>	hap1: 1 0 0		hap2: 1 0 1;*/
/*/*heteroVec={0 0 1};*/*/
/*/*SNPdat={1 1 0 0 0 1};*/*/
/*/**Possible haplotypes;*/*/
/*/**S1=>	hap1: 1 0 0		hap2: 1 0 1*/*/
/*/**/*/
/*/*heteroVec={0 1 1};*/*/
/*/*SNPdat={1 1 0 1 0 1};*/*/
/*/**Possible haplotypes;*/*/
/*/**S1=>hap1: 1 1 0 hap2: 1 0 1*/*/
/*/**S2=>hap1: 1 1 1 hap2: 1 0 0*/*/
/*/**/*/
/*/*heteroVec={1 1 1};*/*/
/*/*SNPdat={0 1 0 1 0 1};*/*/
/*/**Possible haplotypes;*/*/
/*/**S1=>hap1: 1 1 1 hap2: 0 0 0*/*/
/*/**S2=>hap1: 1 0 1 hap2: 0 1 0*/*/
/*/**S3=>hap1: 1 1 0 hap2: 0 0 1*/*/
/*/**S4=>hap1: 1 0 0 hap2: 0 1 1*/*/
/*/**/*/
/*/*heteroVec={0 0 0};*/*/
/*/*SNPdat={1 1 1 1 1 1};*/*/
/*/* *Possible haplotypes;*/*/
/*/**S1=>hap1: 1 1 1 hap2: 1 1 1*/*/
/*/* Get possible haplotype combinations */*/
/*myhaplos = getHaplos(SNPdat, heteroVec);*/
/*print myhaplos;*/
/*numHaploComb = nrow(myhaplos);*/
/*haploLabs = makeHaploLabN(0:(2**numSNPs - 1), numSNPs);*/
/*print haploLabs;*/
/**/
/*haploDM1= codeHaploDM(myhaplos, haploLabs);*/
/*print haploDM1;*/
/**/;

*https://blogs.sas.com/content/iml/2012/08/20/how-to-return-multiple-values-from-a-sasiml-function.html;
start RecodeHaplos(haploDM, nonHaploDM, ID_vec, wt, nonzeror_dummy_haps, init_hap_frq, dat, numSNPs, maxMissingGenos, verbose);

    ncols = ncol(dat);
    /* Split dat into nonSNP and SNP data */ 
        if verbose=1 then do;
            print "Haplotypes will be based on the SNPs (allelic format)";
				end;
    
    nonsnpcols = ncols - 2 * numSNPs;
    snpcols = ncols - nonsnpcols;
    nonSNPdat = dat[, 1:(ncols - 2 * numSNPs)];
    
    nonSNPdat = nonSNPdat || J(nrow(nonSNPdat), 1, 1); /* Add a constant column of 1s */

    SNPdat = dat[, (ncols - 2 * numSNPs + 1):ncols];
    
    /* Process missing data */
    preProcDat = handleMissings(SNPdat, nonSNPdat, numSNPs, maxMissingGenos);

    SNPdat = preProcDat[,2:2*numSNPs+1];
/*		print preProcDat;*/
    nonSNPdat = preProcDat[,2*numSNPs+2:ncols+2];
    ID = preProcDat[,1];
    
    /* Initialization and setup */
    haploLabs = makeHaploLabN(0:(2**numSNPs - 1), numSNPs);
    numHaplos = nrow(haploLabs);
    
    /* Build data frames */
		*Note: one extra column at the end of the nonSNPdat has been added;
		*So nonsnpcols+1;
    nonHaploDM = j(nrow(SNPdat) * 2**(numSNPs - 1), nonsnpcols+1, .);
    nhdmidx = 1;
    haploDM = j(nrow(SNPdat) * 2**(numSNPs - 1), numHaplos, .);
    hdmidx = 1;
    haploMat = j(nrow(SNPdat) * 2**(numSNPs - 1), snpcols, .);
    hmatidx = 1;
    ID_vec = j(nrow(SNPdat) * 2**(numSNPs - 1), 1, .);
    ididx = 1;
    heteroVec = j(1, numSNPs, .);
    
    /* Main loop to construct design matrix */
    do i = 1 to nrow(SNPdat);
        heteroVec = isHetero(SNPdat[i, ], numSNPs);
        numHetero = sum(heteroVec);
        
        /* Get possible haplotype combinations */
        myhaplos = getHaplos(SNPdat[i, ], heteroVec);
        numHaploComb = nrow(myhaplos);
        
        do j = 1 to numHaploComb;
            /* Loop over haplo combos consistent with observed data */
            haploDM[hdmidx, ] = t(codeHaploDM(myhaplos[j, ], haploLabs));
            hdmidx = hdmidx + 1;
        end;
        
        do j = 1 to numHaploComb;
            nonHaploDM[nhdmidx, ] = nonSNPdat[i, ];
            nhdmidx = nhdmidx + 1;
        end;
        
        do j = 1 to numHaploComb;
            ID_vec[ididx] = ID[i];
            ididx = ididx + 1;
        end;
        
        do j = 1 to nrow(myhaplos);
            haploMat[hmatidx, ] = myhaplos[j, ];
            hmatidx = hmatidx + 1;
        end;
    end;
    
    /* Trim matrices to actual size */
    haploDM = haploDM[1:(hdmidx - 1), ];
    haploMat = haploMat[1:(hmatidx - 1), ];
    ID_vec = ID_vec[1:(ididx - 1), ];
    nonHaploDM = nonHaploDM[1:(nhdmidx - 1), ];
/*    print ididx;*/
/*		print ID_vec;*/
/*		print haploDM;*/
    /* Normalize weights */
		wt = j(nrow(ID_vec), 1, .);
    do i = 1 to (ididx - 1);
        wt[i] = 1 / sum(ID_vec = ID_vec[i]);
    end;
    
    /* Only return columns of haploDM with non-zero column sums */
		dummy_hap_idx=loc(haploDM[+,] > 0);
		*These haplotypes that with non-zero column sums;
/*		haploLabs = makeHaploLabN(0:(2**numSNPs - 1), numSNPs);*/
		nonzeror_dummy_haps=haploLabs[dummy_hap_idx,];
/*		print nonzeror_dummy_haps;*/

    haploDM = haploDM[, dummy_hap_idx];
		init_hap_frq=t(t(wt)*haploDM);
		*It is necessary to get the sum of all elements of init_hap_frq for calculating adjusted haplotype frq;
		init_hap_frq=init_hap_frq/init_hap_frq[+];
/*    print init_hap_frq;*/

    /* Output matrices and weights */
/*		print nonHaploDM;*/
/*		print haploDM;*/
/*		print ID_vec;*/
/*		print wt;*/
/*    outData = haploDM || nonHaploDM || ID_vec || wt; */
/*		print outData;*/
/*    return(outData);*/
finish;

/*Example codes;*/

/*dat={0.1 1 0 0 0 1 1 1,*/
/*			0.2 2 0 1 0 1 1 1,*/
/*			0.4 0 1 1 0 1 0 0*/
/*};*/
/**/
/*create d from dat;*/
/*append from dat;*/
/*close d;*/
/**The above is just for creating a sas dataset for testing purposes;*/
/**as the iml function RecodeHaplos requires to have a sas dataset as input;*/

use &gen_pheno_sasdsd;
read all into test;
/*print test;*/

numSNPs=&numSNPsInDsd;
maxMissingGenos=&maxMissingGenos;
verbose=&verbose;

run RecodeHaplos(haploDM, nonHaploDM, ID_vec, wt,nonzeror_dummy_haps, init_hap_frq, test, numSNPs, maxMissingGenos, verbose);
/*print haploDM;*/
*The initial estimated haplotype frequency can be supplied to hapreg for haplotype association analysis;
/*print nonzeror_dummy_haps init_hap_frq;*/
outData = haploDM || nonHaploDM || ID_vec || wt;
/*print outData;*/


HapFrqWithHaps=init_hap_frq||nonzeror_dummy_haps;
/*Initially estimated haplotype frquencies and its corresponding haplotypes coded by 0 and 1;
Note: the order of these haplotypes are according to the haplotypes in the first colums of haplotypes in the
following output dataset HapDM_outdsd*/
create &Hapfrq_outdsd from HapFrqWithHaps;
append from HapFrqWithHaps;
close &Hapfrq_outdsd;

create &HapDM_outdsd from outData;
append from outData;
close &HapDM_outdsd;

%mend;

/*Demo codes:;
proc iml;
dat={0.1 1 0 0 0 1 1 1,
			0.2 2 0 1 0 1 1 1,
			0.4 0 1 1 0 1 0 0
};

create d from dat;
append from dat;
close d;
*The above is just for creating a sas dataset for testing purposes;
*as the iml function RecodeHaplos requires to have a sas dataset as input;

%InitEstHapFrq(
gen_pheno_sasdsd=d,
numSNPsInDsd=3,
maxMissingGenos=1, 
verbose=1	
);

*Demo codes 2:;
*This hypoDat.txt is from the R package hapassoc, which is modified by adding the ID to its header;
proc import datafile="C:\Users\cheng\Downloads\hapassoc\data\hypoDat.txt"
dbms=dlm out=geno_pheno replace;
delimiter=' ';
getnames=yes;
guessingrows=max;
run;
%InitEstHapFrq(
gen_pheno_sasdsd=geno_pheno,
numSNPsInDsd=3,
maxMissingGenos=1, 
verbose=1	
);

*Test the two macros;
%allele_columns2geno(
dsd=geno_pheno,
cols4alleles=4-9,
outdsd=out
);

%geno2allelecolumns(
dsd=out,
cols4genos=4-6,
outdsd=NewOut
);

%InitEstHapFrq(
gen_pheno_sasdsd=NewOut,
numSNPsInDsd=3,
maxMissingGenos=1, 
verbose=1	
);



*/


