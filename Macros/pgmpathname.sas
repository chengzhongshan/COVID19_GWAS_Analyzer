%macro pgmpathname;
%global pgmpathname;
%let pgmpathname=;

data _null_;
  set sashelp.vextfl;
  if (substr(fileref,1,3)='_LN' or substr
  (fileref,1,3)='#LN' or substr(fileref,1,3)='SYS') and
  index(upcase(xpath),'.SAS')>0 then do;
     xpath1=prxchange('s/(\\)*(\/)*[^\\]+\.sas$//i',-1,trim(xpath));
	 xpath2=prxchange('s/\\/\//',-1,trim(xpath1));
     call symput("pgmpathname",trim(xpath2));
     stop;
  end;
run;
%mend pgmpathname;
/*
%pgmpathname;
%put pgmname=&pgmpathname;
*/
