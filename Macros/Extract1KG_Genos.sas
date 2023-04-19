%macro Extract1KG_Genos(
OneKG_Path,/*Use forward slish and No slish at the end*/
maf,
SubsetSamplesFile,
Outdir  /*Use forward slish and No slish at the end*/
);

%get_filenames(location=&OneKG_Path,dsd_out=OneKG_filenames);  

x cd "&Outdir";

data OneKG_filenames;
set OneKG_filenames(where=(memname contains '.fam'));
memname=prxchange('s/.fam//',-1,memname);
run;


data _null_;
set OneKG_filenames;
plink_cmd='plink1.9.exe --geno 0.1 --snps-only --mind 0.1 --maf '|| "&maf"||' --list-duplicate-vars ids-only suppress-first --bfile '
                     ||"&OneKG_Path/"
					 ||strip(left(memname))
					 ||" --keep &SubsetSamplesFile "
                     ||' --out '
					 ||"&Outdir/"
                     ||strip(left(memname));
call system(plink_cmd);
run;


data _null_;
set OneKG_filenames;
plink_cmd='plink1.9.exe --make-bed --geno 0.1 --snps-only --mind 0.1 --maf '|| "&maf"||' --bfile '
                     ||"&OneKG_Path/"
                     ||strip(left(memname))
					 ||" --keep &SubsetSamplesFile "
					 ||" --exclude "
					 ||"&Outdir/"
                     ||strip(left(memname))
                     ||".dupvar"
                     ||' --out '||"&Outdir/"
                     ||strip(left(memname));
call system(plink_cmd);
run;


/*Generate BED list for merge with plink*/
filename outfile "OneKG_BED_list.txt";
data _null_;
set OneKG_filenames;
file outfile;
put memname;
run;
/*Make macro variable for the first BED for merging with plink*/
data _null_;
set OneKG_filenames(obs=1);
call symput("baseBED",trim(left(memname)));
run;
/*Merge plink beds*/
/*Make sure to double quote file path*/
%let plink_cmd=%str(plink1.9.exe --bfile "&baseBED" --merge-list "OneKG_BED_list.txt" 
                     --out "&Outdir/Merged");
%put &plink_cmd;
x &plink_cmd;

/*If failed in merger process, try to remove these variants*/

%if %FileOrDirExist(&filepath) eq 1 %then %do;

data _null_;
set OneKG_filenames;
plink_cmd='plink1.9.exe --make-bed --geno 0.1 --snps-only --mind 0.1 --maf '|| "&maf"||' --bfile '
                     ||strip(left(memname))
					 ||" --keep &SubsetSamplesFile "
					 ||" --exlude Merged.missnp "
                     ||' --out '
                     ||"&Outdir/"
                     ||strip(left(memname));
call system(plink_cmd);
run;


/*Generate BED list for merge with plink*/
filename outfile "OneKG_BED_list.txt";
data _null_;
set OneKG_filenames;
file outfile;
put memname;
run;
/*Make macro variable for the first BED for merging with plink*/
data _null_;
set OneKG_filenames(obs=1);
call symput("baseBED",trim(left(memname)));
run;
/*Merge plink beds*/
/*Make sure to double quote file path*/
%let plink_cmd=%str(plink1.9.exe --bfile "&baseBED" --merge-list "OneKG_BED_list.txt" 
                     --out "&Outdir/Merged");
%put &plink_cmd;
x &plink_cmd;

%end;

%mend;

/*Any path should use forward slish and No slish at the end*/

/*Demo:

options mprint mlogic symbolgen noxwait;

%let outdir=E:/Coorperator_projects/LCL_SRA_Project/LCL_Bacteria_Host_Interaction/YRI_CEU_1KG;
%delete_all_files_in_folder(&outdir);

%Extract1KG_Genos(
OneKG_Path=E:/D_Queens/SASGWASDatabase/Important_Analysis_Codes/PExFInS_SAS/Databases/1KG_Phase3,
maf=0.05,
SubsetSamplesFile=E:/Coorperator_projects/LCL_SRA_Project/LCL_Bacteria_Host_Interaction/LCL_EUR_YRI_Bacteria_Samples.txt,
Outdir=E:/Coorperator_projects/LCL_SRA_Project/LCL_Bacteria_Host_Interaction/YRI_CEU_1KG
);

*/
