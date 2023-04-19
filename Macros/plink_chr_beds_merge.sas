%macro plink_chr_beds_merge(
PLINK_EXE,
BED_dsd,
plink_chr_beds_path,
WorkDir,
SNP_File,
KeepIDsFile,
extra_plink_cmd,
OutBed
);
/*Go working directory*/
/*filter plink BED with several QC parameters*/

%if %sysfunc(prxmatch(/^\//,&WorkDir)) %then %do;
*For Linux system;
x cd &WorkDir;
%end;
%else %do;
*For windows system;
x cd "&WorkDir";
%end;

%if %eval("&SNP_File"^="" and "&KeepIDsFile"^="") %then %do;
data _null_;
set &BED_dsd;
plink_cmd="&PLINK_EXE"||' --make-bed --snps-only '||"&extra_plink_cmd"||' --bfile "'
                     ||"&plink_chr_beds_path/"
                     ||strip(left(memname))
                     ||'" --extract '
                     ||"&SNP_File"
                     ||" --keep &KeepIDsFile "
                     ||' --out '
                     ||strip(left(memname))||'_tmp';
call system(plink_cmd);
run;
%end;
%else %if ("&SNP_File"="" and "&KeepIDsFile"^="") %then %do;
data _null_;
set &BED_dsd;
plink_cmd="&PLINK_EXE"||' --make-bed --snps-only '||"&extra_plink_cmd"||' --bfile "'
                     ||"&plink_chr_beds_path/"
                     ||strip(left(memname))||'" '
                     ||" --keep &KeepIDsFile "
                     ||' --out '
                     ||strip(left(memname))||'_tmp';
call system(plink_cmd);
run;
%end;
%else %if ("&SNP_File"^="" and "&KeepIDsFile"="") %then %do;
data _null_;
set &BED_dsd;
plink_cmd="&PLINK_EXE"||' --make-bed --snps-only '||"&extra_plink_cmd"||' --bfile "'
                     ||"&plink_chr_beds_path/"
                     ||strip(left(memname))||'" '
                     ||" --extract &SNP_File "
                     ||' --out '
                     ||strip(left(memname))||'_tmp';
call system(plink_cmd);
run;
%end;
%else %if ("&SNP_File"="" and "&KeepIDsFile"="") %then %do;
data _null_;
set &BED_dsd;
plink_cmd="&PLINK_EXE"||' --make-bed --snps-only '||"&extra_plink_cmd"||' --bfile "'
                     ||"&plink_chr_beds_path/"
                     ||strip(left(memname))||'" '
                     ||' --out '
                     ||strip(left(memname))||'_tmp';
call system(plink_cmd);
run;
%end;
%else %do;
%put Please check your parameters: SNP_File and KeepIDsFile;
%abort 255;
%end;


data _null_;
set &BED_dsd;
plink_cmd="&PLINK_EXE"||' --list-duplicate-vars ids-only suppress-first --bfile "'
                     ||strip(left(memname))||'_tmp'
                     ||'" --out '
                     ||strip(left(memname));
call system(plink_cmd);
run;

data _null_;
set &BED_dsd;
plink_cmd="&PLINK_EXE"||' --bfile "'
                     ||strip(left(memname))||'_tmp'
                     ||'" --exclude '
                     ||strip(left(memname))
                     ||'.dupvar'
                     ||' --make-bed --out '
                     ||strip(left(memname));
call system(plink_cmd);
run;


/*Generate BED list for merge with plink*/
filename outfile "OneKG_BED_list.txt";
data _null_;
set &BED_dsd;
file outfile;
put memname;
run;
/*Make macro variable for the first BED for merging with plink*/
data _null_;
set &BED_dsd(obs=1);
call symput("baseBED",trim(left(memname)));
run;
/*Merge plink beds*/
/*Make sure to double quote file path*/

%let plink_cmd=%str(&PLINK_EXE --bfile "&baseBED" --merge-list OneKG_BED_list.txt
                     --out &OutBed);
%put &plink_cmd;
x &plink_cmd;

%mend;


/*Demo:

%get_filenames(location=E:\D_Queens\SASGWASDatabase\Important_Analysis_Codes\PExFInS_SAS\Databases\1KG_Phase3
              ,dsd_out=filenames);

data filenames;
set filenames;
memname=prxchange("s/\.(bed)//",-1,memname);
where memname contains ".bed";
run;
proc sort data=filenames nodupkeys;by _all_;run;


*Only focus on specific chr for debugging;
data filenames;
set filenames;
*where memname contains 'chr10';
run;

*options mprint mlogic symbolgen noxwait;

%plink_chr_beds_merge(
PLINK_EXE=plink1.9.exe,
BED_dsd=filenames,
plink_chr_beds_path=E:\D_Queens\SASGWASDatabase\Important_Analysis_Codes\PExFInS_SAS\Databases\1KG_Phase3,
WorkDir=E:\Yale_GWAS\WGS_SSADA_Analysis\WGS_vs_1KG\TestHere,
SNP_File=,
KeepIDsFile=,
extra_plink_cmd=--allow-no-sex --geno 0.2 --mind 0.2 --maf 0.01 --hwe 0.0000001,
OutBed=Merge
);

*/
