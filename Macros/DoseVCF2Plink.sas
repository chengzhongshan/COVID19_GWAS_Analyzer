%macro DoseVCF2Plink(DoseVCF,GP,PlinkOut);
data _null_;
call system("plink1.9.exe --vcf &DoseVCF --vcf-min-gp &GP --make-bed --out &plinkOut");
run;
%mend;
/*
%DoseVCF2Plink(DoseVCF=E:\Yale_GWAS\GWCIDR_GWGO\GWGO_GWCIDR.1kg_phase3_v5.chr13.dose.vcf.gz,GP=0.9,PlinkOut=Tmp);
*/
