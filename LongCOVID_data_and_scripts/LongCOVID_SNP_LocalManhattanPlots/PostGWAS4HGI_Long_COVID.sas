/*
gwas_names:
Long COVID HGI - DF4 W1 => gwas number 91854
Long COVID HGI - DF4 N2 => gwas number 192226
Long COVID HGI - DF4 W2=> gwas number 826733
Long COVID HGI - DF4 N1=> gwas number 793752

Strict cases of long COVID after test-verified SARS-CoV-2 infection (n = 3,018) vs. general population controls (n = 994,582), 
with its download link provided as (https://my.locuszoom.org/gwas/192226/?token=09a18cf9138243db9cdf79ff6930fdf8).
DF4-N2

Broad long COVID cases identified as infected by any SARS-CoV-2 virus (n = 6,450) vs. general population controls (n = 1,093,995), 
with its download link provided as (https://my.locuszoom.org/gwas/826733/?token=c7274597af504bf3811de6d742921bc8).
DF4-W2

Strict long COVID cases defined (n = 2,975) vs. strict controls restricted to individuals who were infected by SARS-CoV-2 but were not diagnosed 
with long COVID (n = 37,935): with its download link provided as (https://my.locuszoom.org/gwas/793752/?token=0dc986619af14b6e8a564c580d3220b4).
DF4-N1

Broad long COVID cases defined (n = 6,407) vs. strict controls as defined in (n = 46,208): 
with its download link provided as (https://my.locuszoom.org/gwas/91854/?token=723e672edf13478e817ca44b56c0c068).
DF4-W1

These long COVID GWASs were combined into a wide-format table and can be imported into SAS for post-GWAS analysis;
*/

*https://sesug.org/proceedings/sesug_2024_SAAG/PresentationSummaries/Papers/151_Final_PDF.pdf;
*options mprint mlogic symbolgen;
filename M url "https://raw.githubusercontent.com/chengzhongshan/COVID19_GWAS_Analyzer/main/Macros/importallmacros_ue.sas";
%include M;
Filename M clear;
%importallmacros_ue(MacroDir=%sysfunc(pathname(HOME))/Macros,fileRgx=.,verbose=0);
/* %macroparas(macrorgx=HGI); */

%ImportFileHeadersFromZIP( 
zip=%sysfunc(pathname(HOME))/CombineLongCOVIDGWAS.gz,/*Only provide file with .gz, .zip, or common text file without comporession 
Note: it is necessary to have fullpath for the input file!*/ 
filename_rgx=., 
obs=max, 
sasdsdout=WideLongCOVIDGWASs, 
deleteZIP=0, 
infile_command=%str(
firstobs=2 obs=max dlm='09'x dsd truncover;
input 
chrom
pos
rsid :$15.
ref :$1.
alt :$1.
neg_log_pvalue4W2
beta4W2
stderr_beta4W2
alt_allele_freq4W2
neg_log_pvalue4W1
beta4W1
stderr_beta4W1
alt_allele_freq4W1
neg_log_pvalue4N2
beta4N2
stderr_beta4N2
alt_allele_freq4N2
neg_log_pvalue4N1
beta4N1
stderr_beta4N1
alt_allele_freq4N1;
/*
firstobs=1 obs=2;
input;
info=_infile_;
*/
), 
/*Better to use nrbquote to replace str and use unquote within the macro 
to get back the input infile_command;*/ 
extra_infile_macrovar_prefix=infile_cmd,/*To prevent the crash of sas when the length of the macro var infile_command is too long, 
it is better to assign different parts of infile commands into multiple global macro vars with similar prefix, such as infile_cmd; 
it is better to use bquote or nrbquote to excape each extra infile command!*/ 
num_infile_macro_vars=0,/*Provide positve number to work with the global macro var of extra_infile_macrovar_prefix*/ 
use_zcat=0, 
var4endlinenum=adj_endlinenum, /*make global var for the endline number but it is 
necessary to use syminputx in the infile_command to record the endline number; 
call symputx("&var4endlinenum",trim(left(put(_n_,8.)))); 
It is possible to assign other numeric value generated in the infile_command to 
this macro var for other purpose, because this global macro var will be accessible 
by other outsite macros! 
call symputx('adj_endlinenum',trim(left(put(rowtag,8.))));*/ 
global_var_prefix4vars2drop=drop_var,/*To handle the issue of trunction of macro var infile_command if there are too many variables to be dropped in the infile procedure; 
it is feasible to create global macro variables with the same prefix, such as drop_var, to exclude them*/ 
num_vars2drop=0 /*Provide postive number to work with the macro var global_var_prefix4vars2drop to resolve these variables to be excluded*/ 
);

libname D "%sysfunc(pathname(HOME))";
proc datasets nolist;
copy in=work out=D memtype=data move;
select 	WideLongCOVIDGWASs;
run;

libname D "%sysfunc(pathname(HOME))";
/*
proc print data=D.WideLongCOVIDGWASs(obs=1);
run;
data D.WideLongCOVIDGWASs(drop=neg_log:);
set D.WideLongCOVIDGWASs;
pvalue4W2=10**(-neg_log_pvalue4W2);
pvalue4W1=10**(-neg_log_pvalue4W1);
pvalue4N2=10**(-neg_log_pvalue4N2);
pvalue4N1=10**(-neg_log_pvalue4N1);
run;
data D.WideLongCOVIDGWASs;
set D.WideLongCOVIDGWASs;
if rsid="" then rsid=catx(':',chrom,pos);
run;
*/

data tgts;
input rsid :$15. type :$10. gene :$10.;
cards;
rs10890422	Hosp	CYP4B1
rs11208552	Both	JAK1
rs7515509	Hosp	AK5
rs41264915	Hosp	THBS3
rs1275969	Hosp	CIB4
rs1123573	Both	BCL11A
rs150345524	Hosp	SF3B1
rs17078348	Hosp	SLC6A20
rs2290859	Both	NXPE3
rs7684660	Hosp	ANAPC4
rs10066378	Hosp	SLC22A5
rs9260038	Hosp	HLA-A
rs1634761	Hosp	HLA-C
rs17219281	Hosp	HLA-DQA1
rs12660421	Hosp	FOXP4
rs2897075	Both	ZKSCAN1
rs11766643	Hosp	TFR2
rs1120591	Both	RAB2A
rs79611697	Hosp	CCDC171
rs149533170	Both	IFNA21
rs505922	Both	ABO
rs61860402	Hosp	SFTPD
rs35705950	Hosp	MUC5B
rs2924480	Both	ELF5
rs10774679	Hosp	OAS3
rs5023077	Hosp	FBRSL1
rs12585036	Hosp	ATP11A
rs150497803	Both	FOXG1
rs117169628	Hosp	SLC22A31
rs9916158	Both	GSDMA/B
rs3785884	Hosp	MAPT
rs1378358	Both	NSF
rs75432325	Both	TAC4
rs7251000	Hosp	DPP9
rs12976386	Both	MUC16
rs34536443	Both	TYK2
rs492602	Both	FUT2
rs1405655	Hosp	NR1H2
rs2834164	Hosp	IFNAR2
rs76608815	Hosp	SLC5A3
rs12329760	Hosp	TMPRSS2
rs190509934	Hosp	ACE2
rs9799354	Nonhosp	NLGN1
rs201484359	Nonhosp	SLC27A6
rs62401842	Nonhosp	KCTD16
rs112842080	Nonhosp	CPLX2
rs147171940	Nonhosp	PIM1
rs76392050	Nonhosp	MTHFD1L
rs4737438	Nonhosp	PENK
rs148340257	Nonhosp	CSPP1
rs10760104	Nonhosp	CDK5RAP2
rs55654117	Nonhosp	MBL2
rs61858037	Nonhosp	NRG3
rs61939166	Nonhosp	KIF21A
rs367777	Nonhosp	NAV3
rs56143829	Nonhosp	WASF3
rs9570861	Nonhosp	PCDH20
rs11454577	Nonhosp	AKAP6
rs113067468	Nonhosp	CRISPLD2
rs115744301	Nonhosp	TRPV3
rs11869231	Nonhosp	COX10
rs6049828	Nonhosp	SYNDIG1
;
proc freq data=tgts;
table type;
run;

proc sql;
create table tgts as 
select *,%AnyOf(vars=pvalue4W1 pvalue4W2 pvalue4N1 pvalue4N2, cond=lt 0.05) as AnyPSig
from(
select a.*,b.type,b.gene
from D.WideLongCOVIDGWASs as a,
         tgts as b
where a.rsid=b.rsid
)
order by AnyPsig;
data tgt4sig;
set tgts;
where AnyPsig=1;
keep type gene rsid;
run;
proc freq;
table type;
run;
/*
proc print data=D.WideLongCOVIDGWASs;
where rsid="rs10890422";
run;
*/
proc sql;
select trim(left(rsid)) into: longcovid_snps separated by ' '
from tgts 
where AnyPSig=1;
*Note: draw local manhattan for each GWAS by updating the Yaxis_Col_Name, i.e., p value variable from each GWAS;
*p, HGI_B1_p, HGI_B2_p, pval;
/*
%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=D.WideLongCOVIDGWASs,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chrom,
Yaxis_Col_Name=pvalue4W2,
GWAS_dsdout=subset4longcovid,
gwas_thrsd=1,
Mb_SNPs_Nearby=1,
snps=&longcovid_snps,
design_width=1200,
design_height=300
);

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=D.WideLongCOVIDGWASs,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chrom,
Yaxis_Col_Name=pvalue4W1,
GWAS_dsdout=subset4longcovid,
gwas_thrsd=1,
Mb_SNPs_Nearby=1,
snps=&longcovid_snps,
design_width=1200,
design_height=300
);

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=D.WideLongCOVIDGWASs,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chrom,
Yaxis_Col_Name=pvalue4N2,
GWAS_dsdout=subset4longcovid,
gwas_thrsd=1,
Mb_SNPs_Nearby=1,
snps=&longcovid_snps,
design_width=1200,
design_height=300
);

%local_gwas_hits_and_nearby_sigs(
GWAS_SAS_DSD=D.WideLongCOVIDGWASs,
Marker_Col_Name=rsid,
Marker_Pos_Col_Name=pos,
Xaxis_Col_Name=chrom,
Yaxis_Col_Name=pvalue4N1,
GWAS_dsdout=subset4longcovid,
gwas_thrsd=1,
Mb_SNPs_Nearby=1,
snps=&longcovid_snps,
design_width=1200,
design_height=300
);
*/

****************************************************************************************;
proc sort data=tgts;by type AnyPSig rsid;run;
*Draw forest plots for top hits;
%Beta2OR_forest_plot( 
dsdin=tgts, 
beta_var=beta4W2, 
se_var=stderr_beta4W2, 
sig_p_var=pvalue4W2,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_W2, 
figfmt=png,
figwidth=900,
figheight=2000, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);

%Beta2OR_forest_plot( 
dsdin=tgts, 
beta_var=beta4W1, 
se_var=stderr_beta4W1, 
sig_p_var=pvalue4W1,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_W1, 
figfmt=png,
figwidth=900,
figheight=2000, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);

%Beta2OR_forest_plot( 
dsdin=tgts, 
beta_var=beta4N2, 
se_var=stderr_beta4N2, 
sig_p_var=pvalue4N2,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_N2, 
figfmt=png,
figwidth=900,
figheight=2000, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);

%Beta2OR_forest_plot( 
dsdin=tgts, 
beta_var=beta4N1, 
se_var=stderr_beta4N1, 
sig_p_var=pvalue4N1,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_N1, 
figfmt=png,
figwidth=900,
figheight=2000, 
dotsize=6, 
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);

proc sql;
create table LongCOVID_Sub as
select a.*,b.type,b.rsid as tag_snp,b.gene
from tgts as b
left join 
D.WideLongCOVIDGWASs as a
on a.chrom=b.chrom and (a.pos between b.pos - 5e5 and b.pos+5e5);

*Get any taget loci within the 1e6 bp window harboring long COVID SNPs with p < 1e-3;
%let min_p_cutoff=1e-3;
proc sql;
create table tgts_adjacent as
select gene,rsid,pvalue4W1,pvalue4W2,pvalue4N1,pvalue4N2,type,tag_snp
from LongCOVID_Sub 
group by gene
having (pvalue4W1=min(pvalue4W1) and min(pvalue4W1)<=&min_p_cutoff) or 
            (pvalue4W2=min(pvalue4W2) and min(pvalue4W2)<=&min_p_cutoff) or
			(pvalue4N1=min(pvalue4N1) and min(pvalue4N1)<=&min_p_cutoff) or
			(pvalue4N2=min(pvalue4N2) and min(pvalue4N2)<=&min_p_cutoff)
order by gene;
*Further get the SNP with the smallest p value for each gene;
 data tgts_adjacent1(keep=snp gene minp);
 retain minp 0 snp 'xxxxxxxxxxxxxx';
 set tgts_adjacent;
 if first.gene then do;
 	minp=min(of pvalue:);
	snp=rsid;
 end;
 else do;
    minp=ifc(min(of pvalue:)<minp,min(of pvalue:),minp);
    if min(of pvalue:)<minp then snp=rsid;
 end;
 if last.gene then output;
 by gene;
 run;
 proc sql;
 create table tgts_adjacent as
 select a.*,b.minp
 from tgts_adjacent as a,
         tgts_adjacent1 as b
where  a.gene=b.gene and a.rsid=b.snp;

*Add these adjacent SNPs into these top hits and make the forest plots again;
proc sql;
create table tgts_adjacent_assoc as 
select *,%AnyOf(vars=pvalue4W1 pvalue4W2 pvalue4N1 pvalue4N2, cond=lt 0.05) as AnyPSig
from(
select a.*,b.type,b.gene
from D.WideLongCOVIDGWASs as a,
         tgts_adjacent as b
where a.rsid=b.rsid
)
order by AnyPsig;
*Add tag for these genes to indicate these SNPs are adjacent SNPs to top hits;
data tgts_adjacent_assoc;
set tgts_adjacent_assoc;
gene=catx('',gene,'+');
run;
%ds2csv(data=tgts_adjacent_assoc,
csvfile=tgts_adjacent_assoc.csv,
runmode=b);

data tgts_combined;
set tgts tgts_adjacent_assoc;
run;
****************************************************************************************;
proc sort data=tgts_combined;by type gene AnyPSig rsid;run;
*Draw forest plots for top hits;
%Beta2OR_forest_plot( 
dsdin=tgts_combined, 
beta_var=beta4W2, 
se_var=stderr_beta4W2, 
sig_p_var=pvalue4W2,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_W2, 
figfmt=png,
figwidth=1400,
figheight=5000, 
dotsize=6, 
xaxis_value_range=%str(0 to 2 by 0.2),
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);

%Beta2OR_forest_plot( 
dsdin=tgts_combined, 
beta_var=beta4W1, 
se_var=stderr_beta4W1, 
sig_p_var=pvalue4W1,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_W1, 
figfmt=png,
figwidth=1400,
figheight=5000, 
dotsize=6, 
xaxis_value_range=%str(0 to 2 by 0.2),
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);

%Beta2OR_forest_plot( 
dsdin=tgts_combined, 
beta_var=beta4N2, 
se_var=stderr_beta4N2, 
sig_p_var=pvalue4N2,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_N2, 
figfmt=png,
figwidth=1400,
figheight=5000, 
dotsize=6, 
xaxis_value_range=%str(0 to 2 by 0.2),
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);

%Beta2OR_forest_plot( 
dsdin=tgts_combined, 
beta_var=beta4N1, 
se_var=stderr_beta4N1, 
sig_p_var=pvalue4N1,/*adjust the threshold of p in the extra_condition4updatedsd*/ 
marker_var=rsid, 
marker_label=SNP, 
svgoutname=HGI_N1, 
figfmt=png,
figwidth=1400,
figheight=5000, 
dotsize=6, 
xaxis_value_range=%str(0 to 2 by 0.2),
autolegend=0,
y2axis_ticket_var=gene,
extra_condition4updatedsd=%nrstr( 
length sigtag $10.; 
grp=type;
sigtag="";
if &sig_p_var<=0.05 then sigtag="*";
) 
);


data LongCOVID_Sub_hosp  LongCOVID_Sub_Both LongCOVID_Sub_nonhosp;
set LongCOVID_Sub;
if type="Hosp" then output LongCOVID_Sub_hosp;
else if type="Both" then output LongCOVID_Sub_Both;
else  output LongCOVID_Sub_nonhosp;
run;

*Prepare a table looking up chrs and colors;
data chr_colors;
input cls $8.;
chr=_n_;
cards;
cx0072bd
cxd95319
cxedb120
cx7e2f8e
cx77ac30
cx4dbeee
cxa2142f
cx0072bd
cxd95319
cxedb120
cx7e2f8e
cx77ac30
cx4dbeee
cxa2142f
cx0072bd
cxd95319
cxedb120
cx7e2f8e
cx77ac30
cx4dbeee
cxa2142f
cx0072bd
cxd95319
;
run;
proc sort data=LongCOVID_Sub_nonhosp(keep=chrom tag_snp gene) out=nonhosp_snps nodupkeys;
by chrom tag_snp;
run;
proc sql noprint;
create table nonhosp_snps as
select a.*,b.cls
from nonhosp_snps as a
left join
chr_colors as b
on a.chrom=b.chr;
select cls into: nonhosp_chr_colors separated by ' '
from nonhosp_snps 
order by tag_snp;

proc sort data=LongCOVID_Sub_hosp(keep=chrom tag_snp gene) out=hosp_snps nodupkeys;
by chrom tag_snp;
run;
proc sql noprint;
create table hosp_snps as
select a.*,b.cls
from hosp_snps as a
left join
chr_colors as b
on a.chrom=b.chr;
select cls into: hosp_chr_colors separated by ' '
from hosp_snps 
order by tag_snp;

proc sort data=LongCOVID_Sub_Both(keep=chrom tag_snp gene) out=both_snps nodupkeys;
by chrom tag_snp;
run;
proc sql noprint;
create table Both_snps as
select a.*,b.cls
from Both_snps as a
left join
chr_colors as b
on a.chrom=b.chr;
select cls into: Both_chr_colors separated by ' '
from Both_snps 
order by tag_snp;

 data LongCOVID_Sub_nonhosp;
 length snp_gene $20.;
 set  LongCOVID_Sub_nonhosp;
 snp_gene=catx(':',tag_snp,gene);
 run;
/* %debug_macro;*/
%Manhattan4DiffGWASs(
dsdin=LongCOVID_Sub_nonhosp,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=snp_gene,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=pvalue4W1,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=pvalue4W2 pvalue4N1 pvalue4N2, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=6, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=5,
fig_width=1000,
fig_height=700,
fontsize=2,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=&nonhosp_chr_colors,
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three, /*a prefix used to label the output figure*/
angle4xaxis_label=90, /*Adjust the angle of xaxis group labels*/
Use_scaled_pos=1,
sep_chr_grp=1,
xgrp_y_pos=-2, /*Asign the y-axis value for all x-axis group labels;
It is necessary to adjust the value if the default value is out of range;
Try to use -1 to replace -1.5 if the above issue occurred!*/
yoffset_setting=%str(offset=(12,0.5)) /*This macro var is used to extend the bottom and upper y-axis;
which is especially helpful when the position of x-axis group labels assigned by xgrp_y_pos is 
out of the default offset of y-axis */
);

*Split the LongCOVID_Sub_hops into two subsets, with each contain half of genes fron the original dataset;
  proc sql;
  create table LongCOVID_Sub_hosp_new as
  select a.*,b.ord
  from 	LongCOVID_Sub_hosp as a
  left join
 (
 select *,monotonic() as ord
 from (
 select unique gene
 from LongCOVID_Sub_hosp)
) as b
on a.gene=b.gene;
 data LongCOVID_Sub_hosp1 LongCOVID_Sub_hosp2;
 length snp_gene $20.;
 set  LongCOVID_Sub_hosp_new;
 snp_gene=catx(':',tag_snp,gene);
 if  ord<=13 then output LongCOVID_Sub_hosp1;
 else output LongCOVID_Sub_hosp2;
 run;
%Manhattan4DiffGWASs(
dsdin=LongCOVID_Sub_hosp1,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=snp_gene,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=pvalue4W1,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=pvalue4W2 pvalue4N1 pvalue4N2, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=10, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=5,
fig_width=1200,
fig_height=700,
fontsize=2,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=&nonhosp_chr_colors,
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three, /*a prefix used to label the output figure*/
angle4xaxis_label=90, /*Adjust the angle of xaxis group labels*/
Use_scaled_pos=1,
sep_chr_grp=1,
xgrp_y_pos=-3, /*Asign the y-axis value for all x-axis group labels;
It is necessary to adjust the value if the default value is out of range;
Try to use -1 to replace -1.5 if the above issue occurred!*/
yoffset_setting=%str(offset=(12,0.5)) /*This macro var is used to extend the bottom and upper y-axis;
which is especially helpful when the position of x-axis group labels assigned by xgrp_y_pos is 
out of the default offset of y-axis */
);
%Manhattan4DiffGWASs(
dsdin=LongCOVID_Sub_hosp2,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=snp_gene,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=pvalue4W1,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=pvalue4W2 pvalue4N1 pvalue4N2, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=6, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=5,
fig_width=1200,
fig_height=700,
fontsize=2,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=&nonhosp_chr_colors,
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three, /*a prefix used to label the output figure*/
angle4xaxis_label=90, /*Adjust the angle of xaxis group labels*/
Use_scaled_pos=1,
sep_chr_grp=1,
xgrp_y_pos=-2, /*Asign the y-axis value for all x-axis group labels;
It is necessary to adjust the value if the default value is out of range;
Try to use -1 to replace -1.5 if the above issue occurred!*/
yoffset_setting=%str(offset=(12,0.5)) /*This macro var is used to extend the bottom and upper y-axis;
which is especially helpful when the position of x-axis group labels assigned by xgrp_y_pos is 
out of the default offset of y-axis */
);

 data LongCOVID_Sub_Both;
 length snp_gene $20.;
 set  LongCOVID_Sub_Both;
 snp_gene=catx(':',tag_snp,gene);
 run;
%Manhattan4DiffGWASs(
dsdin=LongCOVID_Sub_Both,/*Input GWAS dataset with multiple GWAS p variables put in columns; it is ideal to have sorted GWAS by numeric chr and position*/
pos_var=pos,/*Position variable for markers, such as SNPs*/
chr_var=snp_gene,/*Chromosome variable for markers, such as SNPs; it is better to have numberic chr var as input*/
P_var=pvalue4W1,/*The P var for the 1st GWAS that is put at the bottom of the final manhattan plot*/
Other_P_vars=pvalue4W2 pvalue4N1 pvalue4N2, /*Leave it empty or provide other GWAS P vars in order for making manhattan plots from botton to up*/
logP=1,/*Provide value 1 to indicate the need of performing -log10 caculation for input P_var; Make sure the P_var and Other_P_vars are in the same format!*/
gwas_thrsd=7.3,/*Use it to draw significance reference line in each GWAS track*/
thrsd_line_color=gray,
dotsize=0.5,/*The dot size for scatter plots*/
_logP_topval=6, /*Top -log10P value to truncate GWAS signals and also restrict the max yaxis value of each GWAS track;
Make sure to input EVEN number for the macro, as the macro separate ticks by step 2!*/
y_axix_step=5,
fig_width=1000,
fig_height=700,
fontsize=2,
flip1stGWAS_signal=0, /*When providing value 1, which will draw the 1st GWAS at the bottom in reverse order for the yaxis, 
which means the most significant association will be put close to bottom;
provide value 0 to draw the 1st GWAS in vertical mode!*/
refline_color_4zero=gray, /*Color the manhattan bottom line*/
rm_signals_with_logP_lt=0.5, /*To make the manhattan plot have reference line at association signal of zero,
it is better to remove associaiton signal logP for all GWASs less than the cutoff*/
use_uniq_colors=1, /*Draw scatter plots with different colors for chromosomes;
provide value 0 to use SAS default color scheme;*/
uniq_colors=&nonhosp_chr_colors,
gwas_sortedby_numchrpos=0, /*Ideally the input GWAS dsdin should be sorted by numchr and pos;
if the GWAS dsdin is not, the macro will sort it accordingly but will require more memory and disk space*/
outputfigname=Manhattan4three, /*a prefix used to label the output figure*/
angle4xaxis_label=90, /*Adjust the angle of xaxis group labels*/
Use_scaled_pos=1,
sep_chr_grp=1,
xgrp_y_pos=-2, /*Asign the y-axis value for all x-axis group labels;
It is necessary to adjust the value if the default value is out of range;
Try to use -1 to replace -1.5 if the above issue occurred!*/
yoffset_setting=%str(offset=(12,0.5)) /*This macro var is used to extend the bottom and upper y-axis;
which is especially helpful when the position of x-axis group labels assigned by xgrp_y_pos is 
out of the default offset of y-axis */
);


proc sql noprint;
select unique(rsid) into: nonhosp_snps	 separated by ' '
from tops
where  grp="Nonhosp";
select unique(rsid) into: hosp_snps	 separated by ' '
from tops
where  grp="Hosp";


libname D "%sysfunc(pathname(HOME))";
*It is only needed to run once for importing the hg19 GTF file;
%let gtf_gz_url=https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_48/gencode.v48.basic.annotation.gtf.gz;
/* %debug_macro; */
%get_genecode_gtf_data(
gtf_gz_url=&gtf_gz_url,
outdsd=D.GTF_HG38
);

%SNP_Local_Manhattan_With_GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro*/
gwas_dsd=LongCOVID_Sub,
chr_var=chrom,
AssocPVars=pvalue4W1 pvalue4W2 pvalue4N1 pvalue4N2,
SNP_IDs=rs3907022,
/*if providing chr:pos or chr:st:end, it will query by pos;
Please also enlarge the dist2snp to extract the whole gene body and its exons,
altought the final plots will be only restricted by the input st and end positions!*/
dist2snp=200000,
/*in bp; left or right size distant to each target SNP for the Manhattan plot*/
SNP_Var=rsid,
Pos_Var=pos,
gtf_dsd=D.GTF_HG38,
ZscoreVars=beta4W1 beta4W2 beta4N1 beta4N2,/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
gwas_labels_in_order=LongCOVID_W1 LongCOVID_W2 LongCOVID_N1 LongCOVID_N2,/*If providing _ for labeling each GWAS, 
the _ will be replaced with empty string, which is useful when wanting to remove gwas label 
if only one scatterplot or the label for a gwas containing spaces;
The list will be used to label scatterplots 
by the sub-macro map_grp_assoc2gene4covidsexgwas*/
design_width=800, 
design_height=800, 
barthickness=10, /*gene track bar thinkness*/
dotsize=5, 
dist2sep_genes=100000,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str(), /*where condition to filter input gwas_dsd*/

shift_text_yval=0.1, /*in terms of gene track labels, add positive or negative vale, ranging from 0 to 1, 
                      to liftup or lower text labels on the y axis; the default value is -0.2 to put gene lable under gene tracks;
                      Change it with the macro var pct4neg_y!*/
fig_fmt=png, /*output figure formats: svg, png, jpg, and others*/
pct4neg_y=3, /*the most often used value is 1;
              compacting the bed track y values by increasing the scatterplot scale, 
              which can reduce the bed trace spaces; It seems that two-fold increasement
              leads to better ticks for different tracks!
              Use value >1 will increase the gene tract, while value < 1 will reduce it!
              Note: when there are only 1 or 2 scatterplots, it is better to provide value = 0.5;
              Modify this parameter with the parameter shift_text_yval to adjust gene label!
              Typically, when there are more scatterplots, it is necessary to increase the value of pct4neg_y accordingly;
              If there are only <4 scatterplots, the value would be usually set as 1 or 2;
              */
adjval4header=-0.5, /*In terms of header of each subscatterplot, provide postive value to move up scatter group header by the input value*/
makedotheatmap=0,/*use colormap to draw dots in scatterplot instead of the discretemap;
Note: if makedotheatmap=1, the scatterplot will not use the discretemap mode based on
the negative and postive values of lattice_subgrp_var to color dots in scatterplot*/

color_resp_var=,/*Use value of the var to draw colormap of dots in scatterplot
if empty, the default var would be the same as that of yval_var;*/

makeheatmapdotintooneline=0,/*This will make all dots have the same yaxis value but have different colors 
based on its real value in the heatmap plot; To keep the original dot y axis value, assign 0 to the macro var
This would be handy when there are multiple subgrps represented by different y-axis values! By modifying
the y-axis values for these subgrps, the macro can plot them separately in each subtrack!
*/
var4label_scatterplot_dots= ,/*Make sure the variable name is not grp, which is a fixed var used by the macro for other purpose;
the variable should contain values of target SNPs and other non-targets are asigned with empty values;
Whenever  makeheatmapdotintooneline=1 or 0, it is possible to use values of the var4label_scatterplot_dots to
label specific scatterplot dots based on the customization of the variable predifined by users for the input data set; 
default is empty; provide a variable that include non-empty strings for specific dots in the 
scatterplots;*/
SNPs2label_scatterplot_dots=rs3907022 /*Add multiple SNP rsids to label dots within or at the top of scatterplot
Note: if this parameter is provided, it will replace the parameter var4label_scatterplot_dots!
*/
);


