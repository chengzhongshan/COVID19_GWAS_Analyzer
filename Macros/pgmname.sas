%macro pgmname;
%global pgmpathname;
%let pgmpathname=;

data _null_;
  set sashelp.vextfl;
  if (substr(fileref,1,3)='_LN' or substr
  (fileref,1,3)='#LN' or substr(fileref,1,3)='SYS') and
  index(upcase(xpath),'.SAS')>0 then do;
     xpath1=prxchange('s/(\\)*(\/)*[^\\]+\.sas$//i',-1,trim(xpath));
     call symput("pgmpathname",trim(xpath1));
     stop;
  end;
run;
%mend pgmname;
/*macro usage demo:
%pgmname;
%put pgmname=&pgmpathname;
*/


