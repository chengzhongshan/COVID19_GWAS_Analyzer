
%macro GWAS_Merge_1KG(
OneKG_Path,
OneKG_Pop,
PLINK_EXE,
WorkDir,
User_Imput_GWAS
);

/*In case of input of multiple populations*/
%let re=%sysfunc(prxparse(s/ +/" "/oi));
%let pop_list="%sysfunc(prxchange(&re,-1,&OneKG_Pop))";
%put OneKG_Pops: &pop_list;
%syscall prxfree(re);

%let OneKG_Pop=%sysfunc(prxchange(s/\s+/_/,-1,&OneKG_Pop));

x cd &WorkDir;


/*Plink BED QC*/
data _null_;
GWAS_Tag="&User_Imput_GWAS";
call system("&PLINK_EXE --bfile "||GWAS_Tag||" --allow-no-sex --maf 0.01
            --geno 0.2 --mind 0.2 --hwe 0.0000001 --snps-only --make-bed
            --out User_GWAS_QC");
run;

/*Caculate IBD with plink*/
X "&PLINK_EXE --bfile User_GWAS_QC --allow-no-sex --genome --out IBD";

/*Removed individuals in BED due to Pi-hat >0.4.*/
%Import_Space_Separated_File(abs_filename=IBD.genome,
                                       firstobs=1,
                                       getnames=yes,
                                       outdsd=PLINK);
data Plink;
set Plink;
where PI_HAT>0.4;*QC: Pi-hat should be le 0.4;
run;
data x;
do until (end);
set Plink end=end;
output x;
end;
end=0;
do until (end);
set Plink end=end;
IID1=IID2;
FID1=FID2;
output x;
end;
run;
data x(keep=FID1 IID1);
set x;
IID2=IID1;
FID2=FID1;
run;
data _null_;
set x;
file "Removed_IDs.txt";
put FID1 IID1;
run;

/*Run Plink to remove these the above individuals and check missingness*/
/*X "&PLINK_EXE --remove Removed_IDs.txt --bfile User_GWAS_QC --allow-no-sex
            --make-bed --out User_GWAS_QC_IBD";*/

/*Keep all samples and ignor these samples with high IBD*/            
X "&PLINK_EXE --bfile User_GWAS_QC --allow-no-sex
            --make-bed --out User_GWAS_QC_IBD";            
            
            
%abort_when_file_not_exit(User_GWAS_QC_IBD.bed);
/*To obtain a missing chi-sq test (i.e. does, for each SNP, missingness differ between*/
/*cases and controls?), use the option:*/
X "&PLINK_EXE --bfile User_GWAS_QC_IBD --allow-no-sex --test-missing";
/*Haplotype-based test for non-random missing genotype data*/
X "&PLINK_EXE --bfile User_GWAS_QC_IBD --allow-no-sex --test-mishap";

%Import_Space_Separated_File(abs_filename=User_GWAS_QC_IBD.bim,
                                firstobs=1,
                                getnames=NO,
                                outdsd=PLINK);
data Plink;
set Plink;
if ( compress(catx("",trim(var5),trim(var6)))
      in ("AT","TA",
              "CG","GC")
    ) then do;
tag=-9;
end;
run;

data _null_;
set Plink(where=(tag=-9));
file "User_GWAS_QC_IBD.rm";
put var2;
run;

/*Create MAP for rsID updating*/
X "&PLINK_EXE --bfile User_GWAS_QC_IBD --make-bed
                --exclude User_GWAS_QC_IBD.rm --out User_GWAS_QC_IBD_rm_AT_GC";

/*Update rsID for BIM*/
/*Create OneKG variants dataset*/

%get_filenames(location=&OneKG_Path);

data filenames;
set filenames;
where (upcase(memname) contains ".BIM");
run;



data OneKG_Variants (keep=var1 var2 var4 var5 var6 Indel_label  rename=(var1=chr var2=variant_name var4=Pos var5=A1 var6=A2) compress=yes);
length Indel_label 8.;
set filenames;
filepath="&OneKG_Path"||"/"||memname;
%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
infile dummy filevar=filepath end=eof delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=1;
do until(eof);
  informat VAR1 best32. ;
  informat VAR2 $15. ;
  informat VAR3 best32. ;
  informat VAR4 best32. ;
/*  Only load partial seq for indel to save space*/
  informat VAR5 $2. ;
  informat VAR6 $2. ;
  format VAR1 best12. ;
  format VAR2 $15. ;
  format VAR3 best12. ;
  format VAR4 best12. ;
  format VAR5 $2.;
  format VAR6 $2.;
  input
  VAR1
  VAR2 $
  VAR3
  VAR4
  VAR5 $
  VAR6 $
  ;
  Indel_label=IFC((length(var5)+length(var6)>2),length(var5)+length(var6),0);
  output;
end;
if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;
/*Map MAP to OneKG variants dataset*/
%Import_Space_Separated_File(abs_filename=User_GWAS_QC_IBD_rm_AT_GC.bim,
                                firstobs=1,
                                getnames=NO,
                                outdsd=PLINK);
data plink;
set plink;
Numb=_n_;
/*For SNPArray, no indel in it, so assigning 0 to it*/
*Indel_label=length(scan(var2,3,":"))-1;
indel_label=0;
rename var5=A1
       var6=A2
       var1=chr
       var2=SNP
       var4=Pos;
run;


proc sql;
create table User_GWAS_SNPArray_QC(compress=yes) as
select b.variant_name,b.A1 as A1_1KG, b.A2 as A2_1KG, a.*
from PLINK as a
left join
OneKG_Variants as b
on (a.Pos=b.Pos and
    a.Chr=b.Chr and
    a.Indel_label=b.Indel_label
)
order by Numb;

/*Exclude mismatched SNPs;*/
%CompareGenoA1A2(User_GWAS_SNPArray_QC,A1,A2,A1_1KG,A2_1KG,User_GWAS_SNPArray_QC1);

*Remove duplicates for Plink MAP;
proc sort data=User_GWAS_SNPArray_QC1 nodupkeys dupout=duplicates_debugging;
by Numb;
run;


data User_GWAS_SNPArray_QC2(keep=chr snp var3 pos A1 A2);
set User_GWAS_SNPArray_QC1;
if variant_name^="" then SNP=variant_name;
else Pos=-9;
if substr(SNP,1,2)^="rs" then Pos=-9;
if upcase(A1)="I" or upcase(A1)="D" then Pos=-9;
/*file "User_GWAS_QC_IBD_rm_AT_GC.bim";*/
/*line=catx('09'x,compress(put(chr,$2.)),snp,var3,pos,A1,A2);*/
/*put line;*/
run;
proc export data=User_GWAS_SNPArray_QC2 dbms=tab replace outfile="User_GWAS_QC_IBD_rm_AT_GC.bim";
putnames=no;
run;


/*For potential erros when used different postion system (such as hg18 or hg38) in the GWAS*/
data _null_;
miss_n=0;
set User_GWAS_SNPArray_QC2 end=eof;
if Pos=-9 then miss_n=miss_n+1;
if eof then do;
 pct=100*miss_n/_n_;
 call symputx('Pct_SNP_Kept',pct);
end;
run;

%if %eval(&Pct_SNP_Kept>70) %then %do;
  %put Please check you GWAS bim file and make sure the postion is in hg19 built;
  %ds2csv(data=User_GWAS_SNPArray_QC1,runmode=b,csvfile=User_GWAS_SNPArray_QC1.csv);
  %abort 255;
%end;


*Remove dup vars;
/*
data User_GWAS_SNPArray_QC2;
n=1;
set User_GWAS_SNPArray_QC2;
if SNP=lag(SNP) then do;
  n=n+1;
  Pos=-9;SNP=catx('_',SNP,n);
end;
drop n;  
run;
*/


/*Create BED again*/
X "&PLINK_EXE --bfile User_GWAS_QC_IBD_rm_AT_GC --make-bed
                --maf 0.01 --geno 0.2 --mind 0.2 --hwe 0.0000001
                --out User_GWAS_QC_IBD_rm_AT_GC1";

/*Only keep these SNPs in 1KG reference*/
X "&PLINK_EXE --bfile User_GWAS_QC_IBD_rm_AT_GC1 --write-snplist
                --out KeepSNPs";
%abort_when_file_not_exit(User_GWAS_QC_IBD_rm_AT_GC1.bed);

*Make Phenotype for comparsion between controls;
proc import datafile="&OneKG_Path/phase3_integrated_calls.20130502_ALL_panel.txt"
      dbms=tab out=OneKG_Pops replace;
          getnames=no;
          guessingrows=100000;
run;
/*Only interested in the comparsion between User_GWAS GWAS controls and 1KG EAS Populations*/
/*Output EAS IDs for extracting Plink BED*/
data _null_;
set OneKG_Pops(where=(upcase(Var4) in %str(%(&pop_list%))));
/*set OneKG_Pops;*/
file "&OneKG_Pop..txt";
put var1 var1;
run;

%get_filenames(location=&OneKG_Path,dsd_out=filenames);
data filenames;
set filenames;
memname=prxchange("s/\.(bed)//",-1,memname);
where memname contains ".bed";
run;
proc sort data=filenames nodupkeys;by _all_;run;


/*Only focus on specific chr for debugging*/
data filenames;
set filenames;
/*where memname contains 'chr10';*/
run;

%OneKG_Assemble(
PLINK_EXE=plink1.9,
BED_dsd=filenames,
OneKG_Path=&OneKG_Path,
WorkDir=&WorkDir,
SNP_File=KeepSNPs.snplist,
KeepIDsFile=&OneKG_Pop..txt,
extra_plink_cmd=--allow-no-sex --geno 0.2 --mind 0.2 --maf 0.01 --hwe 0.0000001,
OutBed=MergedOneKG
);


%MergePlinkBeds(Plink_EXE=&PLINK_EXE
               ,BaseBed=MergedOneKG
               ,OtherBed2Merge=User_GWAS_QC_IBD_rm_AT_GC1
               ,OutBed=Merged_
               ,DelTmpFiles=1);


/*Important: QC to remove missing SNPs again; otherwise, GWAS samples will have different PCA pattern as that of the 1KG*/
/*Make sure not use mind 0.1*/
/*This part would be very useful to remove ALL SNPs that were not included in the USER INPUT GWAS*/
%let plink_cmd=%str(&PLINK_EXE --bfile Merged_ --snps-only --geno 0.2 --maf 0.01 --hwe 0.0000001 --make-bed --out Merged_1);
%put &plink_cmd;
X &plink_cmd;



X "&PLINK_EXE -allow-no-sex --bfile Merged_1 --indep-pairwise 50 10 0.2 --out Merged_Prune1";

/*Measure IBS between all samples*/
X "&PLINK_EXE -allow-no-sex --bfile Merged_1 --extract Merged_Prune1.prune.in --genome --out ibs1";
/*Clustering*/
/*For case-control, use --cluster cc*/
X "&PLINK_EXE -allow-no-sex --bfile Merged_1 --read-genome ibs1.genome --cluster group-avg --mds-plot 10 --out strat1";

/*Visualization of populations clusters*/
/*Import Cluster info*/
%Import_Space_Separated_File(abs_filename=strat1.mds,
                             firstobs=1,
                             getnames=yes,
                             outdsd=mds);

/*Update Population info into FAM*/
proc sql;
create table FAM_Pops as
select a.*,b.var3 as OneKGSub,b.var4 as OneKG
from mds as a
left join
OneKG_Pops as b
on a.FID=b.var1;

data FAM_Pops;
length pop $8.;
set Fam_Pops;
if substr(FID,1,2)="HG" or substr(FID,1,2)="NA" then pop=OneKG;
else pop="My";
run;

%ds2csv(data=FAM_Pops,runmode=b,csvfile=MDS_Output.csv);



proc template;
define statgraph sgdesign;
dynamic _C1A _C2A _POP;
begingraph / designwidth=794 designheight=695;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      layout overlay;
         scatterplot x=_C1A y=_C2A / group=_POP name='scatter';
         discretelegend 'scatter' / opaque=false border=true halign=left valign=bottom displayclipped=true across=1 order=rowmajor location=inside;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=WORK.FAM_POPS template=sgdesign;
/*where pop in ('My','YRI','EUR');*/
dynamic _C1A="C1" _C2A="C2" _POP="POP";
run;





options mprint mlogic symbolgen;

/*
%get_filenames(location=%bquote(&cwd),dsd_out=filenames,match_rgx=^(?!.*sas|&User_Imput_GWAS));
%del_files_in_dsd(dsd=filenames,filevar=memname,indir=&cwd);
*/


symbol1 v=dot c=green;
symbol2 v=diamond c=cyan;
symbol3 v=+ c=blue;
symbol4 v=circle c=red;
proc gplot data=FAM_Pops;
/*where pop in ('YRI','CEU','EA2','AA2','IBS');*/
/*where pop in ("C","S","CHB","CHS");*/

/*compare with AFR groups;*/
/*where pop in ('CEU','AA1','YRI','PUR','EA1');*/

/*compare with EUR groups;*/
/*where pop in ('AA2','EA2','TSI','IBS','GRB','CEU','FIN');*/

/*compare with AMR groups;*/
/*where pop in ('AA2','MXL','CLM','PEL','PUR','YRI');*/

plot C1*C2=pop;
run;


%mend;

/*Demo:

%let MacroDir=/project/fas/gelernter/zc254/SAS/SAS-Useful-Codes/Macros;
%include "&MacroDir/ImportAllMacros.sas";
%ImportAllMacros(MacroDir=&MacroDir,filergx=.*);
*options xmin;

%let OneKG_Path=/gpfs/loomis/project/fas/gelernter/zc254/STRiPPaperSuppl/1KG_Phase3;
%let PLINK_EXE=plink1.9;
%let User_Imput_GWAS=Jan2018;
*Make sure the GWAS fam has case-control pheno;
*Need to be in upcase; Could be multiple pops separated by blank spaces; EUR,AFR,SAS,EAS;
%let OneKG_Pop=EUR; 
*Will get subsamples from the 1KG sample info file in &OneKG_Path;

%GWAS_Merge_1KG(
OneKG_Path=&OneKG_Path,
OneKG_Pop=&OneKG_Pop,
PLINK_EXE=plink1.9,
WorkDir=/gpfs/loomis/project/fas/gelernter/zc254/Yale_GWAS/RFMix/Post-QC-master,
User_Imput_GWAS=Jan2018
);

*/
