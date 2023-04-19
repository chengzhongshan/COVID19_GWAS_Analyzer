%macro RunKggseq( java_bin=        /* Only single comma; when just run java with 'java -jar', it does not work, as sas use its inernal java */
                 , Kggseq_dir=      /* Windows path of directory to Kggseq jar                                                         */
                 , dir=             /* variant file directory                                                                          */
                 , var_file_name=   /* file contains variants to be processed by Kggseq                                                */
                 , input_file_cmd=  /* --vcf-file filepath or annovar-file filepath                                                    */
                 , pheno_cmd=       /* --ped--file filename N.B.: 1:unaff,2:aff,0:unknown                                              */
                 , other_params=    /* Kggseq parameters for filters (make excel as output)                                            */
                 ) ;
/*Important other_params:
#one argument per line 
#Enviromental setting
--buildver hg19 \ 
#--resource ./resources \  

#Specify the input files
#--vcf-file I:/SKCM/TCGA/Protected_Mutations/BI__IlluminaGA_DNASeq_Cont/Level_2/TCGA-BF-A1PU_30ba63c3-2425-434a-ae62-d4fe1479f3c0_b53844f5-2249-4ce5-9ea7-e7a0286ee5ec.oxoG.snp.capture.tcga.vcf \ 
#--indiv-pheno  NORMAL:1,PRIMARY:2 \ 


#Output setting
--out ./test0808_1 \ 
--excel \ 
--o-seattleseq \  
--o-vcf \  
#--o-flanking-seq 50 \ 
 
#QC
--gty-qual 10 \ 
--gty-dp 4 \  
--gty-af-ref 0.05 \  
--gty-af-alt 0.25 \  
--vcf-filter-in PASS \  
--seq-qual 50 \ 
--seq-mq 20 \ 
--seq-sb 0 \ 
--min-obsa 1 \ 
#--min-obsu 1 \ 

 #Filtering and Prioritization 
--genotype-filter 2,3,4  \ 
#--ibs-case-filter 1000 \ 
--db-gene refgene \ 
--gene-feature-in 6 \ 

--db-filter hg19_1kg201204,hg19_dbsnp137,hg19_ESP6500AA,hg19_ESP6500EA \ 
--db-filter-hard dbsnp138nf
--rare-allele-freq 0.006 \ 
--db-score dbnsfp \ 
--filter-nondisease-variant \
--regions-out chrX,chrY \ 

#Annotation
--genome-anot \  
#--candi-list ECEL1,MYBPC1,TNNI2,TNNT3,TPM2 \ 
#--pubmed-mining Arthrogryposis,Arthrogryposis+multiplex+congenita \ 

#--pathway-annot cura \  
#--ppi-annot string \
#--ppi-depth 1 \  
*/
 
options noxwait XSYNC;

/*The command prompt window closes automatically when the application finishes;*/
/*SAS waits for the application to finish.;*/
%local Kggfullpath;
%let Kggfullpath=%bquote(&Kggseq_dir/Kggseq.jar);
%let other_params=%bquote(&other_params);
%let pheno_cmd=%bquote(&pheno_cmd);

/*Make sure the &java_bin is quoted by single quote and &Kggseq_dir/resources has blank at its tail*/
data _null_;
file "&dir/temp.bat" lrecl=32767;
put "&java_bin -Xmx3g -jar &Kggseq_dir/Kggseq.jar -resource &Kggseq_dir/resources &input_file_cmd %bquote(&dir/&var_file_name) %bquote(&pheno_cmd) &other_params";
run;
x &dir/temp.bat;
%mend;


/*
* *options mprint mlogic symbolgen noxwait xsync;
* %let vcf_dir=I:/SKCM/TCGA/Protected_Mutations/BI__IlluminaGA_DNASeq_Cont/Level_2;
* %let vcf=TCGA-BF-A1PU_30ba63c3-2425-434a-ae62-d4fe1479f3c0_b53844f5-2249-4ce5-9ea7-e7a0286ee5ec.oxoG.snp.capture.tcga.vcf;
* 
* %VCF2KggPED(dir=&vcf_dir
*             ,filename=&vcf
*             ,dsdout=temp_ped /*file will be in directory &dir and non-word will be changed into '_'*/
*             ,unaff=normal
*             ,aff=primary);
* 
* /*Get abbr of "Program Files" by: dir /x C:\ in windows*/
* %RunKggseq(  java_bin=C:\Progra~1\Java\jre7\bin\java
*             ,Kggseq_dir=E:/kggseq10
*             ,dir=&vcf_dir
*             ,var_file_name=&vcf
*             ,input_file_cmd=--vcf-file
*             ,pheno_cmd=--ped-file &vcf_dir/temp_ped
*             ,other_params=--out &vcf_dir/Test --excel --o-vcf --gty-qual 10 --gty-dp 4 --genotype-filter %str(2,3,4) --db-gene refgene --gene-feature-in 6 --db-filter %str(hg19_1kg201204,hg19_dbsnp137,hg19_ESP6500AA,hg19_ESP6500EA) 
*);
*/;


/*Important other_params:
#one argument per line 
#Enviromental setting
--buildver hg19 \ 
#--resource ./resources \  

#Specify the input files
#--vcf-file I:/SKCM/TCGA/Protected_Mutations/BI__IlluminaGA_DNASeq_Cont/Level_2/TCGA-BF-A1PU_30ba63c3-2425-434a-ae62-d4fe1479f3c0_b53844f5-2249-4ce5-9ea7-e7a0286ee5ec.oxoG.snp.capture.tcga.vcf \ 
#--indiv-pheno  NORMAL:1,PRIMARY:2 \ 


#Output setting
--out ./test0808_1 \ 
--excel \ 
--o-seattleseq \  
--o-vcf \  
#--o-flanking-seq 50 \ 
 
#QC
--gty-qual 10 \ 
--gty-dp 4 \  
--gty-af-ref 0.05 \  
--gty-af-alt 0.25 \  
--vcf-filter-in PASS \  
--seq-qual 50 \ 
--seq-mq 20 \ 
--seq-sb 0 \ 
--min-obsa 1 \ 
#--min-obsu 1 \ 

 #Filtering and Prioritization 
--genotype-filter 2,3,4  \ 
#--ibs-case-filter 1000 \ 
--db-gene refgene \ 
--gene-feature-in 6 \ 

--db-filter hg19_1kg201204,hg19_dbsnp137,hg19_ESP6500AA,hg19_ESP6500EA \ 
--db-filter-hard dbsnp138nf
--rare-allele-freq 0.006 \ 
--db-score dbnsfp \ 
--filter-nondisease-variant \
--regions-out chrX,chrY \ 

#Annotation
--genome-anot \  
#--candi-list ECEL1,MYBPC1,TNNI2,TNNT3,TPM2 \ 
#--pubmed-mining Arthrogryposis,Arthrogryposis+multiplex+congenita \ 

#--pathway-annot cura \  
#--ppi-annot string \
#--ppi-depth 1 \  
*/
