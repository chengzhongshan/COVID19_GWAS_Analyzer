%macro systran(prog,pathin,pathout,dsname);
options xwait;
%sysexec("&prog." &pathin.&dsname..sas7bdat &pathout.&dsname..dta /Y);
options xwait;
run;
%mend;

*%systran(C:\Program Files\StatTransfer7\st.exe,c:\data\,d:\data\,tempx);

