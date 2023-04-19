
%macro LocalScatterplots4MultGWASs(
longformatgwasfile,
Chr_var,
Pos_var,
GWAS_var,
beta_var,
rsid_var,
P_var,
subChr,
subStPos,
subEndPos,
otherfilters4whereCondition,
rsid_reflinepos,
rsid_ref,
log10pRef,
pcutoff,
FigHeight,
FigWidth
);

%if %sysfunc(exist(work.x)) %then %do;
%put using previous SAS dataset work.x1 for making scatterplot;
%end;
%else %do;
proc import datafile="&longformatgwasfile" 
dbms=tab out=x replace;
getnames=yes;guessingrows=100000000;
run;

proc print data=x(obs=10);run;

*narrow down to the region chr2:131,323,787-141,323,786 (hg19: 10Mb);
data x;
set x(rename=(&GWAS_var=GWAS));
/**subset a 10Mb region with rs16831827, chr2:136323787 at the center;*/
/*where pos between 131323787 and 141323787;*/

/**subset a 1Mb region with rs16831827, chr2:136323787 at the center;*/
/*where pos between 135823787 and 136823787;*/

*subset a 2Mb region with rs16831827, chr2:136323787 at the center;
where &Chr_var=&subChr and (&Pos_var between &subStPos and &SubEndPos)
%if %length(&otherfilters4whereCondition)	%then %do;
					 and &otherfilters4whereCondition
%end;
;
run;
%end;

data x1(keep=GWAS POS log10P assoc rsid);
length assoc $50.;
set x;
if &beta_var>0 then assoc='Positive';
else assoc='Negative';
if &Pos_var=&rsid_reflinepos then assoc=trim(left(assoc))||"-&rsid_ref";
log10P=-log10(&P_var);
where &P_var<&pcutoff or &Pos_var=&rsid_reflinepos;
label log10P="-log10(P) of COVID-19 association signals"
      &Pos_var="Chromosome 2 position";
      
run;


/*proc export data=x1(log10P>4)) outfile="top_MAP3K19_signals.txt" replace;*/
/*run;*/

/*proc export data=x1(where=(pos between 134472167 and 137078991 and log10P>4)) outfile="top_MAP3K19_signals.txt" replace;*/
/*run;*/

/*
ods graphics on /ANTIALIASMAX=436200 height=1600px width=1200px;
*narrow down the region to chr2:134,472,167-137,078,991;
proc sgpanel data=x1;
*where gwas not contains ('HGI');
*where pos between 134472167 and 137078991 and gwas contains ('HGI');
panelby gwas/columns=4 novarname onepanel uniscale=all;
*panelby gwas/columns=1 novarname onepanel uniscale=all;
scatter x=POS y=log10P/group=assoc markerattrs=(symbol=circlefilled size=5);
colaxis display=none;
refline 1.3/axis=y lineattrs=(thickness=2 color=darkred pattern=thindot);
refline 136323787/axis=x lineattrs=(thickness=2 color=darkred pattern=thindot);
run;

proc sql;
select min(pos) as min_st,max(pos) as max_end
from x1;
*/

/*data x2;*/
/*set x1;*/
/*if POS=128698683 then rsid="rs200763002";*/
/*if rsid="NA" then rsid="2:"||trim(left(put(POS,best12.)));*/
/*where (log10P>=2)*/
/*      or pos=136323787;*/
/*where (log10P>=2) and (pos between 134472167 and 137078991)*/
/*      or pos=136323787;*/
/*run;*/

proc sort data=x1;by gwas log10P;run;
data x1;
set x1;
if last.gwas then top=&rsid_var;
by gwas;
text_y=log10P+0.2;
if top='NA' then top="Chr&subChr.:"||strip(left(put(&Pos_var,12.)));
*Add customized markder for highlight;
if rsid="rs6759321" then top=rsid;
if pos=136801328 then top='rs62160874';
run;

/*ods graphics on /ANTIALIASMAX=436200 height=1600px width=1200px;*/
ods graphics on /ANTIALIASMAX=500000 height=&FigHeight.px width=&FigWidth.px;
*narrow down the region to chr2:134,472,167-137,078,991;
proc sgpanel data=x1;
/*where prxmatch('/AFR/',upcase(gwas));*/
panelby gwas/columns=1 novarname onepanel uniscale=all;
/*where gwas not contains ('HGI');*/
*where pos between 134472167 and 137078991 and gwas contains ('HGI');
/*panelby gwas/columns=4 novarname onepanel uniscale=all;*/
*panelby gwas/columns=1 novarname onepanel uniscale=all;
scatter x=&Pos_var y=log10P/group=assoc markerattrs=(symbol=circlefilled size=11);
text x=&Pos_var y=text_y text=top/ textattrs=(family='arial' size=9pt color=dark weight=bold);
colaxis display=none;
refline &log10pref/axis=y lineattrs=(thickness=2 color=darkred pattern=thindot);
*refline 4/axis=y lineattrs=(thickness=2 color=darkred pattern=thindot);
refline &rsid_reflinepos/axis=x lineattrs=(thickness=2 color=darkred pattern=thindot);
run;

/*ods graphics on /ANTIALIASMAX=436200 height=3600px width=1200px;*/
/**narrow down the region to chr2:134,472,167-137,078,991;*/
/*proc sgpanel data=x1;*/
/*where gwas not contains ('HGI');*/
/**where pos between 134472167 and 137078991 and gwas contains ('HGI');*/
/**panelby gwas/columns=4 novarname onepanel uniscale=all;*/
/*panelby gwas/columns=1 novarname onepanel uniscale=all;*/
/*scatter x=POS y=log10P/group=assoc;*/
/*colaxis display=none;*/
/*run;*/
/**/
/*proc sql;*/
/*select min(pos) as min_st,max(pos) as max_end*/
/*from x1;*/

%mend;

/*Demo:
options mprint mlogic symbolgen;
x cd "I:\Backup_tar_gz\UKB_Hospitalization_GWAS";
%let longformatgwasfile=MAP3K19_chr2_126323786_146323788_snps.assoc.HGI_plus_UKB.txt;

%LocalScatterplots4MultGWASs(
longformatgwasfile=MAP3K19_chr2_126323786_146323788_snps.assoc.HGI_plus_UKB.txt,
Chr_var=_chr,
Pos_var=Pos,
GWAS_var=TabixDB,
beta_var=beta,
rsid_var=rsid,
P_var=p,
subChr=2,
subStPos=135823787,
subEndPos=136823787,
otherfilters4whereCondition= %str(prxmatch("/(B1_ALL|B2_ALL|hsptl_(ALL|AFR|EUR|SAS|OTHERS))/i",gwas)) 
and gwas not contains 'tested' and gwas not contains 'pstv' and gwas not contains '_F' and gwas not contains '_M',
rsid_reflinepos=136323787,
rsid_ref=rs16831827,
log10pRef=1.3,
pcutoff=0.05,
FigHeight=1600,
FigWidth=1200
);


%LocalScatterplots4MultGWASs(
longformatgwasfile=MAP3K19_chr2_126323786_146323788_snps.assoc.HGI_plus_UKB.txt,
Chr_var=_chr,
Pos_var=Pos,
GWAS_var=TabixDB,
beta_var=beta,
rsid_var=rsid,
P_var=p,
subChr=2,
subStPos=135823787,
subEndPos=136823787,
otherfilters4whereCondition= %str(prxmatch("/[AC]\d_ALL/i",gwas)) 
and gwas not contains 'tested' and gwas not contains 'pstv' and gwas not contains '_F' and gwas not contains '_M',
rsid_reflinepos=136323787,
rsid_ref=rs16831827,
log10pRef=1.3,
pcutoff=0.05,
FigHeight=1200,
FigWidth=1200
);

*/
