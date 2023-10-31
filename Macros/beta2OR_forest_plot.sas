%macro Beta2OR_forest_plot(
dsdin=,
beta_var=,
se_var=,
sig_p_var=,/*adjust the threshold of p in the extra_condition4updatedsd*/
marker_var=,
marker_label=,
svgoutname=,

extra_condition4updatedsd=%nrstr(
length sigtag $10.;
if &marker_var="rs16831827" then do;
 grp=0;sigtag='';
end;
else if &sig_p_var<5e-8 then do;
 grp=1;sigtag='*';
end;
else do;
 grp=1;sigtag="";
end;
if &marker_var="12:113357193:G:A" then &marker_var="rs10774671";
if &marker_var="17:44219831:T:A" then &marker_var="rs1819040";
if &marker_var="19:10427721:T:A" then &marker_var="rs74956615";

if &marker_var in ('rs2271616','rs11919389','rs912805253','rs4801778') then grp=0;
else if &marker_var='rs16831827' then grp=1;
else grp=2;
)

);
data tmp;
set &dsdin;
effect=exp(&beta_var);
uppercl=exp(&beta_var+1.96*&se_var);
lowercl=exp(&beta_var-1.96*&se_var);
%unquote(&extra_condition4updatedsd);
run;

options printerpath=(svg out) nobyline;
filename out "&svgoutname..svg";
ods listing close;
ods printer;
title "OR Forest Plot";
ods graphics on/reset=all noborder outputfmt=svg;
proc sgplot data=tmp noautolegend;
/* scatter x=effect y=&marker_var / datalabel=sigtag */
scatter x=effect y=&marker_var / datalabel=sigtag 
datalabelattrs=(size=12) 
group=grp xerrorlower=lowercl 
xerrorupper=uppercl
markerattrs=(symbol=circleFilled size=12);
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 valueattrs=(size=12);
yaxis label="&markder_label" valueattrs=(size=12);
run;
ods printer close;
ods listing;

%mend;

/*Demo:;


*/
