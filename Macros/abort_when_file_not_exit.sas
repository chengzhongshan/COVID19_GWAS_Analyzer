%macro abort_when_file_not_exit(filepath);
%if %FileOrDirExist("&filepath") eq 0 %then %do;
    %put no file for &filepath;
    %abort 255;
%end;
%else %do;
    %put file &filepath exists!;
%end;
%mend;

