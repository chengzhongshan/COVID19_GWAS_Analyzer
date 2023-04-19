%macro OneKG_Assemble(
PLINK_EXE,
BED_dsd,
OneKG_Path,
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
                     ||"&OneKG_Path/"
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
                     ||"&OneKG_Path/"
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
                     ||"&OneKG_Path/"
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
                     ||"&OneKG_Path/"
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

data beds;
set &BED_dsd;
run;
/*The following macro will overwrite &BED_dsd if &BED_dsd is 'filenames'*/

/*Read plink log file to check ERROR info for each BED_dsd.log*/
%ImportAllFilesInDirbyScan(filedir=.
                 ,fileRegexp=.*tmp.log
                 ,dsdout=logs
                 ,firstobs=0
                 ,dlm='09'x
                 ,ImportAllinChar=1
                 ,MissingSymb=NaN
                 ,notverbose=1
                 ,debug=0
);

/*Get plink log with error info*/
proc sql;
create table logs_failed as
 select prxchange('s/_tmp\.log//',-1,memname) as bed
 from logs
 where prxmatch('/Error:/i',V1);
 
proc sql;
create table Successful_BEDs as
select a.*
from beds as a
where memname not in (
 select bed
 from logs_failed
);

/*Generate BED list for merge with plink*/
filename outfile "OneKG_BED_list.txt";
data _null_;
set Successful_BEDs;
file outfile;
put memname;
run;

/*Make macro variable for the first BED for merging with plink*/
data _null_;
set Successful_BEDs end=eof;
if _n_=1 then do;call symput("baseBED",trim(left(memname)));end;
if _n_=eof then do; call symput('tot_n',trim(left(_n_)));end;
run;

%put You have created two macro vars: baseBed=&baseBED and tot_n=&tot_n;


/*Merge plink beds*/
/*Make sure to double quote file path*/
%if %eval(&tot_n > 1) %then %do;
%let plink_cmd=%str(&PLINK_EXE --bfile "&baseBED" --merge-list OneKG_BED_list.txt
                     --out &OutBed);
%end;
%else %if (&tot_n=1) %then %do;
%let plink_cmd=%str(&PLINK_EXE --bfile "&baseBED" --make-bed 
                     --out &OutBed);
%end;
%else %do;
%put No beds from any chrs were kept;
%abort 255;
%end;
                    
%put &plink_cmd;
x &plink_cmd;

%mend;


/*Demo:

   %let MacroDir=/project/fas/gelernter/zc254/SAS/SAS-Useful-Codes/Macros;
   %include "&MacroDir/ImportAllMacros.sas";
   %ImportAllMacros(MacroDir=&MacroDir,filergx=.*);
   *options xmin;


   %get_filenames(location=/gpfs/loomis/project/fas/gelernter/zc254/STRiPPaperSuppl/1KG_Phase3
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

   %OneKG_Assemble(
   PLINK_EXE=plink1.9,
   BED_dsd=filenames,
   OneKG_Path=/gpfs/loomis/project/fas/gelernter/zc254/STRiPPaperSuppl/1KG_Phase3,
   WorkDir=.,
   SNP_File=KeepSNPs.snplist,
   KeepIDsFile=,
   extra_plink_cmd=--allow-no-sex --geno 0.2 --maf 0.01 --hwe 0.0000001,
   OutBed=Merge
   );



*/
