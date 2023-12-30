%macro VarnamesInDsd(indsd,Rgx,match_or_not_match,outdsd,keepvarnum=0);
proc contents data=&indsd out=&outdsd(keep=name type VARNUM) noprint;
run;
proc sort data=&outdsd;by VARNUM;run;
data &outdsd;
set &outdsd;
%if &match_or_not_match %then %do;
if prxmatch("/&Rgx/i",name);
%end;
%else %do;
if not prxmatch("/&Rgx/i",name);
%end;
%if &keepvarnum=0 %then %do;
  drop VARNUM;
%end;
run;

%mend;
/*
%VarnamesInDsd(indsd=,Rgx=.*,match_or_not_match=0,outdsd=,keepvarnum=0);
*/

