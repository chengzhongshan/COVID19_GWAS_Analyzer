%macro pname;
%global pgmname;
%let pgmname=;

data _null_;
  set sashelp.vextfl;
  if (substr(fileref,1,3)='_LN' or substr
  (fileref,1,3)='#LN' or substr(fileref,1,3)='SYS') and
  index(upcase(xpath),'.SAS')>0 then do;
     call symput("pgmname",trim(xpath));
     stop;
  end;
run;
%mend pname;

/*
%pname;
%put pgmname=&pgmname;
*/

