
%macro trunc_dsdname(dsdname,st_substr=1); /*Make sas data name in the range of 1 to 32*/
/*dsdname can not contain more than 32 chracters;*/
/*Revised it accordingly;*/
%if &st_substr<%length(&dsdname) %then %do;
  %let dsdname=%sysfunc(prxchange(s/\W+/_/,-1,&dsdname));
  %let dsdname=%substr(&dsdname,&st_substr);
  &dsdname
%end;
%else %do;
  %put "You input substr start position is longer than that of &dsdname";
  %put "We will not truncate your input dsdname!";
  &dsdname
%end;
%mend;

/*
data a;
rc=%trunc_dsdname(dsdname=xxxxyssssssssssssssssssssss,st_substr=1);
run;
*/




