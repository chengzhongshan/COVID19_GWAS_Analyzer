
%macro hist4p(dsdin,pvarname=pval,pbins=0 1e-7 1e-5 1e-3 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1,pgrp=g,outdsd=summary);
%make_bin_format(bins=&pbins,out_format_name=Pfrt);
data X;
set X;
P=&pvarname+0;
%if &pgrp ne %then %do;
G=&pgrp;
%end;
run;

proc freq data=X;
%if &pgrp eq %then %do;
table P/out=&outdsd;
%end;
%else %do;
table G*P/out=&outdsd;
%end;
format P Pfrt.;
run;

%if &pgrp eq %then %do;
proc template;
define statgraph sgdesign;
dynamic _P _COUNT;
begingraph / designwidth=640 designheight=904;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      layout overlay / xaxisopts=( discreteopts=( tickvaluefitpolicy=splitrotate));
         barchart category=_P response=_COUNT / name='bar' stat=mean;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=WORK.&outdsd template=sgdesign;
dynamic _P="P"  _COUNT="COUNT";
run;

%end;
%else %do;
proc template;
define statgraph sgdesign;
dynamic _P _G _COUNT;
begingraph / designwidth=640 designheight=904;
   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
      layout overlay / xaxisopts=( discreteopts=( tickvaluefitpolicy=splitrotate));
         barchart category=_P response=_COUNT / group=_G name='bar' stat=mean groupdisplay=Stack clusterwidth=1.0;
         discretelegend 'bar' / opaque=false border=true halign=left valign=center displayclipped=true across=1 order=rowmajor location=inside;
      endlayout;
   endlayout;
endgraph;
end;
run;

proc sgrender data=WORK.&outdsd template=sgdesign;
dynamic _P="P" _G="G" _COUNT="COUNT";
run;


proc template;
define statgraph sgdesign;
dynamic _P _G _COUNT;
dynamic _panelnumber_;
begingraph / designwidth=1214 designheight=746;
   layout datalattice columnvar=_G / cellwidthmin=1 cellheightmin=1 rowgutter=3 columngutter=3 rowdatarange=unionall row2datarange=unionall columndatarange=unionall column2datarange=unionall headerlabeldisplay=value columnaxisopts=( discreteopts=( tickvaluefitpolicy=splitrotate));
      layout prototype / ;
         barchart category=_P response=_COUNT / name='bar' stat=mean barwidth=0.85 groupdisplay=Stack clusterwidth=0.85;
      endlayout;
      sidebar / align=bottom spacefill=false;
         discretelegend 'bar' / opaque=true border=true halign=center valign=center displayclipped=true order=rowmajor;
      endsidebar;
   endlayout;
endgraph;
end;
run;

proc sgrender data=WORK.&outdsd template=sgdesign;
dynamic _P="P" _G="G" _COUNT="COUNT";
run;
%end;

%mend;


/*Demo:
x cd "J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS\UKB_Covid19_GWAS\covid19_Tested_F_vs_M";
proc import datafile="covid_Tested_F_vs_M.csv" dbms=csv out=X replace;
getnames=yes;guessingrows=100000;
run;
data X;
set X;
if male_P<=0.05 and female_P<=0.05 then g=2;
else if male_P<0.05 and female_P>0.05 then g=1;
else if female_P<0.05 and male_P>0.05 then g=-1;
else g=0;
run;
*options mprint mlogic symbolgen;
*Note: by changing the pbins, the macro can be modified to make histogram for other values;
*If no pgrp provided, the macro will only draw histogram for single pval;
%hist4p(dsdin=X,pvarname=pval,pbins=0 1e-7 1e-5 1e-3 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1,pgrp=g,outdsd=summary);

*/

