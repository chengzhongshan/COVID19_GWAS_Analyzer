%macro list_files4dsd(dir,file_rgx,dsdout);
options linesize=max;
proc printto log="&dir/list_files.tmp" new;
run;
%list_files(&dir,&file_rgx);
proc printto;run;
proc printto log=log;
run;
data &dsdout;
length fullpath $500;
infile "&dir/list_files.tmp" dsd;
input;
fullpath=_infile_;
if prxmatch("/&file_rgx/i",fullpath) and prxmatch("/[\/\\]/",fullpath);
run;
%del_file_with_fullpath(fullpath=&dir/list_files.tmp);
%mend;

/*Demo:

%list_files4dsd(
dir=E:\F_Queens\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
file_rgx=sas,
dsdout=x
);

*For UE:
%let UE_Folder=/folders/myshortcuts;
options mautolocdisplay sasautos=("&UE_Folder/E/F_Queens/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros"
sasautos);

%list_files4dsd(
dir=&UE_Folder/E/F_Queens/360yunpan/SASCodesLibrary/SAS-Useful-Codes/Macros,
file_rgx=sas,
dsdout=x
);



*/

