%macro VarnamesInDsd(indsd,Rgx,match_or_not_match,outdsd);
proc contents data=&indsd out=&outdsd(keep=name type) noprint;
run;
data &outdsd;
set &outdsd;
%if &match_or_not_match %then %do;
if prxmatch("/&Rgx/",name);
%end;
%else %do;
if not prxmatch("/&Rgx/",name);
%end;
run;

%mend;
/*
%VarnamesInDsd(indsd=,Rgx=.*,match_or_not_match=0,outdsd=);
*/

