
*options mprint mlogic symbolgen;
%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;
%mkdir(dir=%sysfunc(pathname(HOME))/data);
libname D '%sysfunc(pathname(HOME))/data';

%let gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B1_ALL_20201020.b37.txt.gz;
%get_HGI_covid_gwas_from_grasp(gwas_url=&gwas_url,outdsd=HGI_B1);
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.HGI_B1,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=%str(rs16831827),
design_width=500,
design_height=300,
col_or_row_lattice=1 /*Plot each subplot in a single column or row:
                      1: columnlattice; 0: rowlattice*/
);


%let gwas_url=https://grasp.nhlbi.nih.gov/downloads/COVID19GWAS/10202020/COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz;
%get_HGI_covid_gwas_from_grasp(gwas_url=&gwas_url,outdsd=HGI_B2);
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=work.HGI_B2,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=p,
GWAS_dsdout=xxx2,
gwas_thrsd=5.5,
Mb_SNPs_Nearby=1,
snps=%str(rs16831827),
design_width=500,
design_height=300,
col_or_row_lattice=1 /*Plot each subplot in a single column or row:
                      1: columnlattice; 0: rowlattice*/
);

proc print data=HGI_B2(where=(rsid="rs16831827"));run;
data HGI_B1;set HGI_B1;where AF>0.01;run;
data HGI_B2;set HGI_B2;where AF>0.01;run;

/*
proc print data=D.HGI_B2(obs=10);
%print_nicer;
run;
*/

*options mprint mlogic symbolgen;
%DiffTwoGWAS(
gwas1dsd=HGI_B1,
gwas2dsd=HGI_B2,
gwas1chr_var=chr,
gwas1pos_var=pos,
snp_varname=rsid,
beta_varname=beta,
se_varname=se,
p_varname=P,
gwasout=HGI_B1_vs_B2,
allele1var=ref,
allele2var=alt
);


proc datasets nolist;
copy in=work out=D memtype=data move;
select HGI_B:;
run;

********************************Run with previously saved data**************************;
/* Needle plot for top independent signals */
/* Get top independent signals */
*options mprint mlogic symbolgen;

libname D '%sysfunc(pathname(HOME))/data';

%let macrodir=%sysfunc(pathname(HOME))/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

data a;
set D.HGI_B1_vs_B2;
/*Only focus on snp but not indel*/
where pval<5e-7 and index(rsid,'rs');
run;

%get_top_signal_within_dist(dsdin=a
                           ,grp_var=chr
                           ,signal_var=pval
                           ,select_smallest_signal=1
                           ,pos_var=pos
                           ,pos_dist_thrshd=10000000
                           ,dsdout=tops1);

*Get these top snps from B1 and B2;
proc sql;
create table B1_top as
select *
from D.HGI_B1 
where rsid in (
  select rsid
   from tops1
);
create table B2_top as
select *
from D.HGI_B2 
where rsid in (
  select rsid
   from tops1
);
data B1_B2_top;
set B1_top(in=a) B2_top(in=b);
gwas="B2";
if a then gwas="B1";
run;


data a;
length grp $8.;
set tops1;
if gwas1_z*gwas2_z>0 then grp='Same';
else grp='Opposite';
run;
/* proc export data=a outfile="%sysfunc(pathname(HOME))/data/top_diff_zscore_COVID19_signals.txt" */
/* dbms=tab replace; */
/* run; */

/*Not good enough*/
/* ods graphics/width=1000px height=200px; */
/* proc sgpanel data=a noautolegend; */
/* panelby chr/noborder novarname columns=12; */
/* scatter x=gwas1_z y=gwas2_z/group=grp; */
/* lineparm x=0 y=0 slope=1/lineattrs=(pattern=dash color=red); */
/* run; */

/*sort the dataset by gwas2_z*/
proc sort data=a;by gwas2_z;
data b;
set a(keep=pval rsid chr pos gwas1_z gwas2_z grp);
array _z_{2} gwas1_z gwas2_z;
do i=1 to 2;
   z=_z_{i};
   gwas=vname(_z_{i})||rsid;
   /*Only keep one copy of AssocP*/
   if i=1 then AssocP=-log10(pval);
   else AssocP=.;
   n=_n_;
   output;
end;
drop gwas1_z gwas2_z;
pos=pos+1;
run;

/* ods graphics/width=800px height=400px; */
/* proc sgpanel data=b noautolegend; */
/* panelby chr/border columns=3; */
/* needle x=pos y=z/baseline=0 baselineattrs=(pattern=dash color=darkred) group=i lineattrs=(thickness=5); */
/* colaxis min=1 type=log logbase=10 logstyle=logexponent; */
/* run; */

proc sort data=b out=x nodupkeys;by n;run;
proc sql noprint;
select quote(compress(rsid)) into: names separated by ' '
from x 
order by n;
;
select quote(strip(left(char_num))) into: num_xaxis separated by ' '
from (select put(n,2.) as char_num
from x);
select max(n) into: tot
from x;
/* options mprint mlogic symbolgen; */
data b;
set b;
Psize=1;
run;


%needleplot4snpsdiffzscores(
diffzscore_gwas=D.hgi_b1_vs_b2,
gwas1_z=gwas1_z,
gwas2_z=gwas2_z,
snp_var=rsid,
snps=&names,
diffzscore_p_var=pval,
gwas1pvar=gwas1_p,
gwas2pvar=gwas2_p
);

*Get target GWAS SNPs P values;
data GWAS_SNPs;
input rsID $20.;
cards;
12:113357193:G:A
17:44219831:T:A
19:10427721:T:A
rs10490770
rs11919389
rs13050728
rs1381109
rs16831827
rs17713054
rs1886814
rs2109069
rs2271616
rs4801778
rs67579710
rs72711165
rs77534576
rs912805253
;
proc sql;
create table top_gwas_snps as
select *
from D.HGI_B1_vs_B2 as a,
     GWAS_SNPs as b
     where a.rsid=b.rsid;
%ds2csv(data=top_gwas_snps,csvfile='top_gwas_snps_signals.csv',runmode=b);
%let var_prefix=gwas1;
/**chr12	113357193 G A for rs10774671;*/
/**chr17	44219831 T A for rs1819040;*/
/**chr19	10427721 T A for rs74956615;*/
data tmp;
length sigtag $10.;
set top_gwas_snps;
effect=exp(&var_prefix._beta);
uppercl=exp(&var_prefix._beta+1.96*&var_prefix._se);
lowercl=exp(&var_prefix._beta-1.96*&var_prefix._se);
if rsid="rs16831827" then do;
 grp=0;sigtag='';
end;
else if &var_prefix._p<5e-8 then do;
 grp=1;sigtag='*';
end;
else do;
 grp=1;sigtag="";
end;
if rsid="12:113357193:G:A" then rsid="rs10774671";
if rsid="17:44219831:T:A" then rsid="rs1819040";
if rsid="19:10427721:T:A" then rsid="rs74956615";
run;

*set these GWS SNPs into different groups based on its association with severity or susceptibility;
data tmp;
set tmp;
if rsid in ('rs2271616','rs11919389','rs912805253','rs4801778') then grp=0;
else if rsid='rs16831827' then grp=1;
else grp=2;
run;

options printerpath=(svg out) nobyline;
filename out "&var_prefix..OR.svg";
ods listing close;
ods printer;
title "COVID-19 GWAS HGI-&var_prefix: OR Forest Plot";
ods graphics on/reset=all noborder outputfmt=svg;
proc sgplot data=tmp noautolegend;
/* scatter x=effect y=rsid / datalabel=sigtag */
scatter x=effect y=rsid / datalabel=sigtag 
datalabelattrs=(size=12) 
group=grp xerrorlower=lowercl 
xerrorupper=uppercl
markerattrs=(symbol=circleFilled size=12);
refline 1 / axis=x;
xaxis label="OR and 95% CI " min=0 valueattrs=(size=12);
yaxis label="SNPs" valueattrs=(size=12);
run;
ods printer close;
ods listing;
	
/* proc print data=topsnps_eff; */
/* run; */

****************************************************************************;     
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=D.HGI_B1_vs_B2,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=gwas2_p,
GWAS_dsdout=xxx,
gwas_thrsd=2,
Mb_SNPs_Nearby=1,
snps=%str( 
12:113357193:G:A
17:44219831:T:A
19:10427721:T:A
rs10490770
rs11919389
rs13050728
),
design_width=400,
design_height=800,
col_or_row_lattice=0, /*Plot each subplot in a single column or row:
                      1: columnlattice; 0: rowlattice*/
uniscale4lattice=column
);

/*
12:113357193:G:A for rs10774671
17:44219831:T:A
19:10427721:T:A
rs10490770
rs11919389
rs13050728
rs1381109
rs16831827
rs17713054
rs1886814
rs2109069
rs2271616
rs4801778
rs67579710
rs72711165
rs77534576
rs912805253
*/
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=D.HGI_B1_vs_B2,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chr,
Yaxis_Col_Name=gwas2_p,
GWAS_dsdout=xxx,
gwas_thrsd=2,
Mb_SNPs_Nearby=1,
snps=%str( 
rs1381109
rs16831827
rs17713054
rs1886814
rs2109069
rs2271616
),
design_width=400,
design_height=800,
col_or_row_lattice=0, /*Plot each subplot in a single column or row:
                      1: columnlattice; 0: rowlattice*/
uniscale4lattice=column

);

quit;

*for MAP3K19;
%let minst=135023787;
%let maxend=137000000;
/* %let minst=136023787; */
/* %let maxend=136523787; */
%let chr=2;

*Note: the order of AssocPVars and ZscoreVars should be corresponded;
*The final figure tracts from bottom to up corresponding to the order of the above vars;
libname FM '%sysfunc(pathname(HOME))/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
libname D '%sysfunc(pathname(HOME))/data';

ods graphics on /reset=all;
/* options mprint mlogic symbolgen; */
%map_grp_assoc2gene4covidsexgwas(
gwas_dsd=D.HGI_B1_vs_B2,
gtf_dsd=FM.GTF_HG19,
chr=&chr,
min_st=&minst,
max_end=&maxend,
dist2genes=0,
AssocPVars=pval Orig_pval gwas2_p gwas1_p,
ZscoreVars=diff_zscore Orig_diffzscore gwas2_z gwas1_z,
design_width=800,
design_height=800,
barthickness=7,
dotsize=5,
dist2sep_genes=0.4, /*
this will ensure these genes close to each other to 
be separated in the final gene track; 
(1) give 0 to plot ALL genes in the same line;
(2) give value between 0 and 1 to separate genes based on the pct distance to the whole region;
(3) give value > 1 to use absolute distance to separate genes into different groups;
Customize this for different gene exon track!
*/
where_cndtn_for_gwasdsd=%str() /*add filters to the input gwas_dsd; such as pval < 0.05 or gwas1_p < 0.05 or gwas2_p < 0.05*/,
gwas_pos_var=pos,
gwas_labels_in_order=Normalized_HGI_B1_vs._B2 Raw_HGI_B1_vs._B2 HGI_B2 HGI_B1 /*The order will be from down to up in the final tracks*/
);
