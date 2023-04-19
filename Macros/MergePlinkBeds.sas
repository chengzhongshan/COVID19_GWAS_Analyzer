%macro MergePlinkBeds(Plink_EXE,BaseBed,OtherBed2Merge,OutBed,DelTmpFiles);

/*
*Doesn't work, as some dup snps are not excluded by using plink command --list-duplicate-var;
%RmDups4PlinkBed(Plink_EXE=&Plink_EXE,PlinkBed=&BaseBed,OutBed=&BaseBed.X);
%RmDups4PlinkBed(Plink_EXE=&Plink_EXE,PlinkBed=&OtherBed2Merge,OutBed=&OtherBed2Merge.X);
*/

/*Caution: the sas macro will overwrite the orignal bim, and if erros occurring, bim will be blank;*/
%AdjDupsInBim(BimFullpath=&BaseBed..bim,BimSep='09'x);
%AdjDupsInBim(BimFullpath=&OtherBed2Merge..bim,BimSep='09'x);

%let BaseBedTmp=&BaseBed._tmp;
%RmATGC4PlinkBed(PlinkBed=&BaseBed,NewPlinkBed=&BaseBedTmp,Plink_EXE=&Plink_EXE);

%let TgtBedTmp=&OtherBed2Merge._tmp;
%RmATGC4PlinkBed(PlinkBed=&OtherBed2Merge,NewPlinkBed=&TgtBedTmp,Plink_EXE=&Plink_EXE);


%let M1cmd=&Plink_EXE --allow-no-sex --bfile &BaseBedTmp --bmerge &TgtBedTmp --merge-mode 6 --out M1;
X "&M1cmd";

%if (%FileOrDirExist(M1.missnp)) %then %do;
%let Mtmpcmd=&Plink_EXE --allow-no-sex --bfile &TgtBedTmp --flip M1.missnp --make-bed --out &TgtBedTmp._1;
X "&Mtmpcmd";

%let M2cmd=&Plink_EXE --allow-no-sex --bfile &BaseBedTmp --bmerge &TgtBedTmp._1 --merge-mode 6 --out M2;
X "&M2cmd";

%let M3cmd=&Plink_EXE --allow-no-sex --bfile &BaseBedTmp --exclude M2.missnp --make-bed --out M3;
X "&M3cmd";
%let Mtmpcmd=&Plink_EXE --allow-no-sex --bfile &TgtBedTmp._1 --exclude M2.missnp --make-bed --out &TgtBedTmp._2;
X "&Mtmpcmd";

%let M4cmd=&Plink_EXE --allow-no-sex --bfile M3 --bmerge &TgtBedTmp._2 --out &OutBed;
X "&M4cmd";
%end;
%else %do;
X "&Plink_EXE --allow-no-sex --bfile &BaseBedTmp --bmerge &TgtBedTmp --out &OutBed";
%end;

%if %eval(&DelTmpFiles^= and &DelTmpFiles=1) %then %do;
%delete_all_Appdx_files_in_folder(folder=.,Appendix=tmp);
%delete_all_Appdx_files_in_folder(folder=.,Appendix=tmp1);
%end;

%mend;

/*
x cd "E:\Yale_GWAS\WGS_SSADA_Analysis\WGS_vs_1KG\TestHere";

%let MacroDir=/project/fas/gelernter/zc254/SAS/SAS-Useful-Codes/Macros;
%include "&MacroDir/ImportAllMacros.sas";
%ImportAllMacros(MacroDir=&MacroDir,filergx=.*);

x cd /gpfs/loomis/project/fas/gelernter/zc254/Yale_GWAS/RFMix/Post-QC-master;

options mprint mlogic symbolgen;
%MergePlinkBeds(Plink_EXE=plink1.9,BaseBed=User_GWAS_QC_IBD_rm_AT_GC,OtherBed2Merge=Merged_,OutBed=xxx,DelTmpFiles=);
*/
