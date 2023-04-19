%macro isDir(iPath=,iQuiet=1);
  %local result dname;

  %let result = 0;

  %if %sysfunc(filename(dname,&iPath)) eq 0 %then %do;
    %if %sysfunc(dopen(&dname)) %then %do;
      %let result = 1;
    %end;
    %else %if not &iQuiet %then %do;
      %put ERROR: ISDIR: %sysfunc(sysmsg());
    %end;
  %end;
  %else %if not &iQuiet %then %do;
    %put ERROR: ISDIR: %sysfunc(sysmsg());
  %end;

  &result

%mend;