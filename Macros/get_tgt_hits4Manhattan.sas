%macro get_tgt_hits4Manhattan(/*Note: the macro is able to keep the order of target snps and generate a macro var
called _chr_colors_ according to the chromsomes that these input snps residing in!*/
dsdin=_last_,
snp_var=rsid,
chr_var=chr,
pos_var=pos,
p_var=p,
dsdout=tophits,
target_snps=rs2564978 rs17425819, /*Only focus on regions of these target snps*/
keep_target_snps_order=0,/*Supply value 1 to keep the original input order of target SNPs, otherwise, 
the macro will sort the input target SNPs and also sort _chr_colors_ by sorted SNPs!*/
dist4get_uniq_top_hit=1e6 /*Only get the top one hit among the distance by pos with the top one at the center*/
);

*Note: this global macro var will be used to draw Manhattan plot later;
%global _chr_colors_;
%let _chr_colors_=;

%let _grp_cols_=
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
cxd95319;

%rank4grps(
grps=&_grp_cols_,
dsdout=grpcolsdsd
);

data grpcolsdsd;
set grpcolsdsd;
rename num_grps=&chr_var;
              cls=grps;
run;

%rank4grps(
grps=&target_snps,
dsdout=tgts
);
data tgts;
set tgts;
rename grps=&snp_var;
run;
*Also keep the order of input SNPs by keeping the variable num_grps;
proc sql;
create table top_ind as
select a.*,b.num_grps
from &dsdin as a,
         tgts as b
where a.&snp_var=b.&snp_var;

proc sql;
   create table &dsdout as 
   select a.*,b.&snp_var as tag_snp,b.num_grps
   from &dsdin as a,
            top_ind as b
 where a.&chr_var=b.&chr_var and 
a.&pos_var between (b.&pos_var-0.5*&dist4get_uniq_top_hit) and 
                                     (b.&pos_var+0.5*&dist4get_uniq_top_hit); 


*Now try to match colors for these top hits by chr;
%if &keep_target_snps_order=1 %then %let var4srt_snp=num_grps;
%else %let var4srt_snp=tag_snp;
proc sql noprint;
create table &dsdout as
select a.*,b.cls
from &dsdout as a
left join
grpcolsdsd as b
on a.&chr_var=b.&chr_var;

select distinct cls into: _chr_colors_ separated by ' '
from &dsdout 
order by &var4srt_snp;

%if %totobsindsd(mydata=&dsdout)=0 %then %do;
    *Do not kill the macro as this macro may be used by a macro loop within other macros;
		%put No targets for your quiry snps: &target_snps;
/*    %abort 255;*/
%end;

%mend;
/*
x cd "H:\Coorperator_projects\COVID_Papers_2023\HGI_NonHospitalizationGWASPaper";
libname D ".";
%get_tgt_hits4Manhattan(
dsdin=D.F_vs_m_mixedpop,
snp_var=rsid,
chr_var=chr,
pos_var=pos,
p_var=pval,
dsdout=tophits,
target_snps=rs2564978 rs17425819, 
dist4get_uniq_top_hit=1e6 
);
*Note: the above macro will generate a global macro variable:;
*_chr_colors_, which will be used to draw Manhattan plots by chr;
*Note: now the above macro is included in the following macro;

%Manhattan4DiffGWASs(
    dsdin=tophits,
    pos_var=pos,
    chr_var=tag_snp,
    P_var=GWAS1_P,
    Other_P_vars=GWAS2_P Pval,
    rm_signals_with_logP_lt=0,
    flip1stGWAS_signal=0,
    sep_chr_grp=1,
    fig_width=1200,
    fig_height=600,
    angle4xaxis_label=90,
    xgrp_y_pos=-0.5,
    yoffset_setting=%str(offset=(30,0.5)) 
 );

*Use updated macro to draw local Manhattan plot;
%Manhattan4DiffGWASs(
    dsdin=D.F_vs_m_mixedpop,
    pos_var=pos,
    chr_var=chr,
    P_var=GWAS1_P,
    Other_P_vars=GWAS2_P Pval,
    rm_signals_with_logP_lt=0,
    flip1stGWAS_signal=0,
    sep_chr_grp=1,
    fig_width=1200,
    fig_height=600,
    angle4xaxis_label=90,
    xgrp_y_pos=-0.5,
    yoffset_setting=%str(offset=(30,0.5)),
    draw_local_Manhattan=1,
    target_SNPs=rs2564978 rs7850484 
 );


*/

