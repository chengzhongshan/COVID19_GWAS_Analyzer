%macro HGI2PairwiseGWASPipeline(
gwasfile_dir=F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
gwas1gzfile=COVID19_HGI_B1_ALL_leave_23andme_20210107.b37.txt.gz,
gwas2gzfile=COVID19_HGI_B2_ALL_leave_23andme_20210107.b37.txt.gz,
EUR_AFR_frq_file=EUR_AFR_specific.txt,
tgt_snps=12:113357193:G: 17:44219831:T:A 19:10427721:T:A rs10490770 rs10774671 rs11919389 rs13050728 
rs1381109 rs1819040 rs1886814 rs2109069 rs2271616 rs4801778 rs67579710 rs72711165 rs74956615 rs77534576 rs912805253,
/*snp rsids or chr:pos:ref:alt if no rsid*/
outfile_tag=HGI_release5_gws_hts.diff_zscore,
HGI_release_num=7	/*before release 7, such as 4, 5, and 6, the input data format are same but different from 7*/

);

%let gwasfile_dir=%sysfunc(prxchange(s/\\/\//,-1,&gwasfile_dir));
%put Your dir for your data is &gwasfile_dir;

%Run_7Zip(
Dir=&gwasfile_dir,
filename=&gwas1gzfile,
Zip_Cmd=e, 
Extra_Cmd= -y
);

%Run_7Zip(
Dir=&gwasfile_dir,
filename=&gwas2gzfile,
Zip_Cmd=e, 
Extra_Cmd= -y
);

%HGI2GWASs_Zscore_Calculator(
gwas1_txt_file=%sysfunc(prxchange(s/\.gz//,-1,&gwas1gzfile)),
gwas2_txt_file=%sysfunc(prxchange(s/\.gz//,-1,&gwas2gzfile)),
dsdout=B1_vs_B2,
HGI_release_num=&HGI_release_num
);

*Comparess output for later usage;
%Run_7Zip(
Dir=&gwasfile_dir,
filename=B1_vs_B2.zscore.txt,
Zip_Cmd=a, 
Extra_Cmd=B1_vs_B2.zscore.txt.gz
);

title "The first 10 observations from the data set B1_vs_B2";
proc print data=B1_vs_B2 (obs=10);run;
/*proc print data=B1_vs_B2;*/
/*where snp="rs16831827";*/
/*run;*/

*Make a data set for these target SNPs;
%rank4grps(
grps=&tgt_snps,
dsdout=published_snps
);
data published_snps(keep=snp);
set published_snps;
rename grps=snp;
run;

*HGI release 5 GWS hits;
/*data published_snps;*/
/*input snp :$25.@@;*/
/**Manually input chr:pos for some missing snps;*/
/**chr12	113357193 G Afor rs10774671;*/
/**chr17	44219831 T A for rs1819040;*/
/**chr19	10427721 T A for rs74956615;*/
/*cards;*/
/*19:10427721:T:A*/
/*17:44219831:T:A*/
/*12:113357193:G:*/
/*rs67579710*/
/*rs1381109*/
/*rs10490770*/
/*rs1886814*/
/*rs72711165*/
/*rs10774671*/
/*rs1819040*/
/*rs77534576*/
/*rs2109069*/
/*rs74956615*/
/*rs13050728*/
/*rs67579710*/
/*rs1381109*/
/*rs10490770*/
/*rs1886814*/
/*rs72711165*/
/*rs10774671*/
/*rs1819040*/
/*rs77534576*/
/*rs2109069*/
/*rs74956615*/
/*rs13050728*/
/*rs2271616 rs10490770 rs11919389 rs1886814 rs72711165 rs912805253 */
/*rs10774671 rs77534576 rs1819040 rs4801778 rs2109069 rs74956615 rs13050728*/
/*;*/
/*run;*/
/**/
/**Remove duplicates;*/
/*proc sort data=published_snps nodupkeys;by _all_;run;*/
/**/

/*data t;*/
/*input snp :$25. @@;*/
/*cards;*/
/*rs2271616 rs10490770 rs11919389 rs1886814 rs72711165 rs912805253 */
/*rs10774671 rs77534576 rs1819040 rs4801778 rs2109069 rs74956615 rs13050728*/
/*;*/
/*proc print;run;*/
/*proc sql;*/
/*select **/
/*from published_snps */
/*except */
/*select * */
/*from t;*/

*Import population frequency data for SNPs among EUR and AFR.;
proc import datafile="&EUR_AFR_frq_file" dbms=tab out=frq replace;
getnames=yes;
guessingrows=100000;
run;

/*
proc sql;
create table B1_rand1 as
select b1_beta
from B1_vs_B2 
order by rand('uniform');
create table B1_rand2 as
select b1_se
from B1_vs_B2
order by rand('uniform');
proc sql;
create table B2_rand1 as
select b2_beta
from B1_vs_B2 
order by rand('uniform');
create table B2_rand2 as
select b2_se
from B1_vs_B2 
order by rand('uniform');
data B1_vs_B2_rand;
set B1_rand1;
set B2_rand1;
set B1_rand2;
set B2_rand2;
b1_z=b1_beta/b1_se;
b2_z=b2_beta/b2_se;
run;
*/


/* %let dsd=B1_vs_B2_rand; */
%let dsd=B1_vs_B2;

data final;
set &dsd;
diff_zscore=(b1_beta-b2_beta)/sqrt(b1_se**2+b2_se**2);
if abs(diff_zscore)>3 then do;
   grp=1;x1=b1_z;y1=b2_z;
end;
else do;
   grp=0;x1=.;y1=.;
end;
run;

proc sql;
create table final as 
select a.*,b.snp as gws_hit
from final as a
left join 
published_snps as b
on a.snp=b.snp
;

data final;
set final;
if gws_hit^="" then do;
  x2=b1_z;y2=b2_z;
end;
else do;
  x2=.;y2=.;
end;
run;

proc sql;
select max(diff_zscore) as max_z,
       min(diff_zscore) as min_z
       from final;
*link with afr and eur specific snps;
proc sql;
create table final1 as
select a.*,b.*
from final as a
left join
frq as b
on a.SNP=b.SNP;
data final1;set final1;
if pop_specific="" then pop_specific="Com";
if grp=. then grp=-1;
run;
proc print data=final1(obs=10);run;
proc freq data=final1;
table grp*pop_specific;
run;
data x;
set final1;
/*where SNP=:"rs";*/
run;

/*proc print data=x;*/
/*where SNP="rs16831827";*/
/*run;*/

proc print data=x;
where gws_hit^="";
run;

data gws_hits;
set x;
where gws_hit^="";
run;

*output target hits;
%ds2csv(data=gws_hits,csvfile="&outfile_tag..csv",runmode=b);

*Print these missing target snps;
title "These are missing target SNPs";
proc sql;
select *
from published_snps 
except 
(select snp
 from x
);

/*proc sql;*/
/*select **/
/*from final*/
/*where snp like '12:113357193:G:' or */
/*      snp like '17:44219831:T%' or */
/*      snp like '19:10427721:T%';*/

/* symbol c=darkred v=dot h=0.5; */
/* axis1 order=(-10 to 20 by 2) label=('HGI-B1'); */
/* axis2 order=(-10 to 20 by 2) label=('HGI-B2'); */
/* proc gplot data=final; */
/* plot b1_z*b2_z/haxis=axis1 vaxis=axis2; */
/* run; */
/* data test; */
/* set final(obs=1000); */
/* proc sgplot data=test; */
/* scatter x=b1_z y=b2_z/group=grp; */
/* run; */


ods graphics off;
proc reg data=final;
model b2_z=b1_z;
ods output ParameterEstimates=PE;
run;
data PE;
set PE;
attrib Probt format=best32.;
run;
proc print;run;

data _null_;
set PE;
if _n_=1 then call symput('Int',put(estimate,best6.));
else call symput('Slope',put(estimate,best6.));
run;

*MAXOBS=10953733;
ods graphics on /reset=all ANTIALIASMAX=10953800 noborder;
*To avoid out of memory in JAVA;
*Only SNPs with larger z-score will be plotted;
proc sgplot data=final(where=(abs(b1_z)>=4 or abs(b2_z)>=4)) noautolegend;
inset "Intercept = &Int" "Slope = &Slope"/border title = "Parameter Estimates"
      position=topleft;
scatter y=b2_z x=b1_z/markerattrs=(symbol=circlefilled size=3 color=lightblue) group=grp; 
/*       groupdisplay=cluster group=grp; */
scatter y=y1 x=x1/markerattrs=(symbol=circlefilled size=3 color=darkorange); 
scatter y=y2 x=x2/markerattrs=(symbol=circlefilled size=4 color=darkgreen);
reg y=b2_z x=b1_z/ clm lineattrs=(thickness=3 color=darkred) nomarkers;
refline 3 /axis=x;
refline -3 /axis=x;
refline 3 /axis=y;
refline -3 /axis=y;
xaxis values=(-10 to 20 by 2) label='Z-score of HGI-B1: hospitalized vs. non-hospitalized COVID-19';
yaxis values=(-10 to 20 by 2) label='Z-score of HGI-B2: hospitalized COVID-19 vs. general population';  
label grp="abs(differetial z-score) > 4";   
run;

*Out of memory;
/* proc g3d data=B1_vs_B2; */
/* scatter b1_z*b2_z=diff_zscore; */
/* run; */

proc univariate data=final plots;
/* var b1_z b2_z b1_beta b2_beta; */
var diff_zscore;
run;

/*proc standard data=final m=0 out=final_adj;*/
/*var diff_zscore;*/
/*run;*/
/*proc print data=final_adj(obs=10);*/
/*proc print data=final(obs=10);*/
/*run;*/
/*proc univariate data=final_adj plots;*/
/*/* var b1_z b2_z b1_beta b2_beta; */*/
/*var diff_zscore;*/
/*run;*/

%mend;

/*Demo:

x cd J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\COVID19_HG\covid19_hg_matlab\HGI_GWAS_release5;

%macroparas(macrorgx=list,
dir=F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
issasondemand=0
);
%list_files(.,gz);

*options mprint mlogic symbolgen;

%HGI2PairwiseGWASPipeline(
gwasfile_dir=J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\COVID19_HG\covid19_hg_matlab\HGI_GWAS_release5,
gwas1gzfile=COVID19_HGI_B1_ALL_leave_23andme_20210107.b37.txt.gz,
gwas2gzfile=COVID19_HGI_B2_ALL_leave_23andme_20210107.b37.txt.gz,
EUR_AFR_frq_file=EUR_AFR_specific.txt,
tgt_snps=12:113357193:G: 17:44219831:T:A 19:10427721:T:A rs10490770 rs10774671 rs11919389 rs13050728 
rs1381109 rs1819040 rs1886814 rs2109069 rs2271616 rs4801778 rs67579710 rs72711165 rs74956615 rs77534576 rs912805253,
outfile_tag=HGI_release5_gws_hts.diff_zscore,
HGI_release_num=5
);

***********************************************************************************************************************;
x cd J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\COVID19_HG\covid19_hg_matlab\HGI_GWAS_release4;

%macroparas(macrorgx=list,
dir=F:\360yunpan\SASCodesLibrary\SAS-Useful-Codes\Macros,
issasondemand=0
);
%list_files(.,gz);

*options mprint mlogic symbolgen;

%HGI2PairwiseGWASPipeline(
gwasfile_dir=J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\COVID19_HG\covid19_hg_matlab\HGI_GWAS_release4,
gwas1gzfile=COVID19_HGI_B1_ALL_20201020.b37.txt.gz,
gwas2gzfile=COVID19_HGI_B2_ALL_leave_23andme_20201020.b37.txt.gz,
EUR_AFR_frq_file=J:\Coorperator_projects\ACE2_2019_nCOV\Covid_GWAS_Manuscrit_Related\COVID19_HG\covid19_hg_matlab\HGI_GWAS_release5\EUR_AFR_specific.txt,
tgt_snps=12:113357193:G: 17:44219831:T:A 19:10427721:T:A rs10490770 rs10774671 rs11919389 rs13050728 
rs1381109 rs1819040 rs1886814 rs2109069 rs2271616 rs4801778 rs67579710 rs72711165 rs74956615 rs77534576 rs912805253,
outfile_tag=HGI_release4_gws_hts.diff_zscore,
HGI_release_num=5
);



*/

