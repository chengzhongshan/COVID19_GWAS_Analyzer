%macro get_top_hits4Manhattan(
dsdin=_last_,
snp_var=rsid,
chr_var=chr,
pos_var=pos,
p_var=p,
dsdout=tophits,
p_thrsd=1e-5, /*Only keep these signals with smaller values than the threshold*/
dist4get_uniq_top_hit=1e6 /*Only get the top one hit among the distance by pos with the top one at the center*/
);
*Note: these global macro vars will be used to draw Manhattan plot later;
%global _chr_colors_ _top_snps_;
%let _chr_colors_=;
%let _top_snps_=;

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

proc sql;
create table _top_hits as
select * 
         from &dsdin where &p_var<=&p_thrsd;

%get_top_signal_within_dist(
dsdin=_top_hits,
grp_var=&chr_var,
signal_var=&p_var,
select_smallest_signal=1,
pos_var=&pos_var,
pos_dist_thrshd=&dist4get_uniq_top_hit,
dsdout=top_ind
); 
proc sql noprint;
select &snp_var into: _top_snps_ separated by ' '
from top_ind
order by &snp_var;
%put Top snps are selected: &_top_snps_;
%put They are saved into a global macro variable, _top_snps_;

proc sql;
   create table &dsdout as 
   select a.*,b.&snp_var as tag_snp
   from &dsdin as a,
            top_ind as b
 where a.&chr_var=b.&chr_var and 
a.&pos_var between (b.&pos_var-0.5*&dist4get_uniq_top_hit) and 
                                     (b.&pos_var+0.5*&dist4get_uniq_top_hit); 


*Now try to match colors for these top hits by chr;
proc sql noprint;
create table &dsdout as
select a.*,b.cls
from &dsdout as a
left join
grpcolsdsd as b
on a.&chr_var=b.&chr_var;

select distinct cls into: _chr_colors_ separated by ' '
from &dsdout 
order by tag_snp;
%put Colors for top snps are &_chr_colors_;
%put They are sorted by snps and saved into a global macro variable, _chr_colors_;

%if %totobsindsd(mydata=&dsdout)=0 %then %do;
		%put No hits after filtering with the p value threshold &p_thrsd;
/*    %abort 255;*/
%end;

%mend;
/*
x cd "H:\Coorperator_projects\COVID_Papers_2023\HGI_NonHospitalizationGWASPaper";
libname D ".";
%get_top_hits4Manhattan(
dsdin=D.F_vs_m_mixedpop,
snp_var=rsid,
chr_var=chr,
pos_var=pos,
p_var=pval,
dsdout=tophits,
p_thrsd=5e-6, 
dist4get_uniq_top_hit=1e6 
);
*Note: the above macro is now included in the following macro;
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

%debug_macro;
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
    top_hit_thresd=1e-6 
 );

*/

