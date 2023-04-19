%macro recursivesearchdirs(/*It will run the perl script RecursiveSearchDir.pl in terminal!*/
dirs=~/shared/Macros ~/SAS-Useful-codes,
filergx=.,
out=files
);
%let ndirs=%sysfunc(countc(&dirs,' '))+1;
%put your have supplied &ndirs dirs;
%put which are &dirs;

%do i=1 %to &ndirs;
%let dir=%scan(&dirs,&i,' ');
filename M pipe "RecursiveSearchDir.pl &dir &filergx";
%put your dir for searching is &dir;
data _filesindir_&i;
length path $1000.;
infile M;
input;
path=_infile_;
run;
%end;

data &out;
set _filesindir_:;
run;
proc datasets lib=work noprint;
delete _filesindir_:
run;


%mend;

/*
options mprint mlogic symbolgen;
*It will use the perl script RecursiveSearchDir.pl;
%recursivesearchdirs(dirs=~/shared/Macros ~/SAS-Useful-codes,out=files);
proc print data=files;run;

*/
