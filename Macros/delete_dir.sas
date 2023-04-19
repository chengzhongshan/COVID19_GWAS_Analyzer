%macro delete_dir(dir);
filename del_dir "&dir";
data _null_;
   rc=fdelete('del_dir');
   put rc=;
   msg=sysmsg();
   put msg=;
run;
%mend;
