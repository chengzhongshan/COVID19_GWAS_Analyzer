
%macro RecSearchFiles2dsd(root_path,filter,perlfuncpath,outdsd,outputfullfilepath);
*options nosource nonotes;
%if "&root_path"="." %then %do;
  %put relative path is not allowed, please provide fullpath for the var root_path!;
  %abort 255;
%end;
%else %if %FileOrDirExist(&root_path) ne 1 %then %do;
  %put Searching directory &root_path is not exist!;
  %abort 255; 
%end;

%if %FileOrDirExist(&perlfuncpath) ne 1 %then %do;
  %put perlfunc RecursiveSearchDir4SAS.pl can not be found in the directory &perlfuncpath!;
  %abort 255; 
%end;

filename indata pipe "perl &perlfuncpath/RecursiveSearchDir4SAS.pl &root_path &filter";
data &outdsd(keep=filefullname);
/*filenames generated by macro DirRecursiveSearch are saved in the temp.txt*/
infile indata lrecl=32767;
input;
filefullname=prxchange("s/\\/\//",-1,_infile_);
output;
run;
%if &outputfullfilepath=0 %then %do;
data &outdsd;
set &outdsd;
filefullname=prxchange("s/^.*\/([^\/\\]+)\.pdf$/$1/",-1,strip(filefullname));
run;
%end;
options source notes;
%mend;

/*
In macro RecSearchFiles2dsd
root_path      =>       Searching directory path
filter         =>       perl rgx to match specific files; . will match all files
perlfuncpath   =>       perl script RecursiveSearchDir4SAS.pl path
outdsd         =>       sas output dataset name 
outputfullfilepath =>   0: only filenames will be output, otherwise let it be 1 or missing;
*/


/*option mprint mlogic symbolgen;*/

/*

%RecSearchFiles2dsd(
root_path=F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes,
filter=.sas$,                                   
perlfuncpath=F:/360yunpan/SASCodesLibrary/SAS-Useful-Codes,
outdsd=m,
outputfullfilepath=1);

*For St Jude Projects;
%RecSearchFiles2dsd(
root_path=C:\Users\zcheng\Documents\PROPEL_SV_SNV_Testing\SNVCallerevaluation\ConsensueMuts,
filter=Consensus.txt$,                                   
perlfuncpath=Z:\ResearchHome\ClusterHome\zcheng\SAS-Useful-Codes,
outdsd=CAB_Samples,
outputfullfilepath=1);



*/

