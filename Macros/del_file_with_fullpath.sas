%macro del_file_with_fullpath(fullpath);
data _null_;
   rc=filename("fname","&fullpath");
   if rc=0 and fexist("fname") then
      rc=fdelete("fname");
   rc=filename("fname");
run;
%mend;
