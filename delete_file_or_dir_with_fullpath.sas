%macro delete_file_or_dir_with_fullpath(
file_or_dir_fullpath=
);
filename fileref "&file_or_dir_fullpath";
data _null_;
rc=fdelete('fileref');
run;
filename fileref clear;

%mend;
