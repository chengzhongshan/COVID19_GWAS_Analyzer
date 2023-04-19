%macro getdsdvarsfmt(dsdin,fmtdsdout);
proc contents data=&dsdin out=&fmtdsdout(keep=name format) noprint;run;
%mend;
