%macro GTEx_eQTL_genes_scatterplot(
genes=Apobec3a Apobec3b,
hg38_gtf_dsd=FM.GTF_HG38,
eqtldsdout=tgtgenewidedsd,
min_pos= ,/*restrict the start position in hg38 of local Manhattan plot;
If it is empty, default value would be the minimum start position;*/
max_pos=  ,/*restrict the end position in hg38 of local Manhattan plot;
If it is empty, default value is the maximum end position*/
colormodel= cxFAFBFE cx667FA2 cxD05B5B /*If empty, default color model of blue grey red;
supply different color combinations to draw different heatmap,
such as yellow blue green red;
*/
);
/* geneids=Apobec3a Apobec3h Apobec3b Apobec3c Apobec3d Apobec3f, */
%QueryGTExeQTLs4Genesymbol(
geneids=&genes,
outdsd=gene_eqtls
);
 
/* %let gtf_gz_url=https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_38/gencode.v38.annotation.gtf.gz; */
/* %get_genecode_gft_data(gtf_gz_url=&gtf_gz_url,outdsd=gtf_hg38); */
/*   */
/* proc datasets nolist; */
/* copy in=work out=FM memtype=data move; */
/* select gtf_hg38; */
/* run; */
data gene_eqtls_sub;
length genegrps $100.;
set gene_eqtls;
chr=scan(chromosome,1,'chr')+0;
call symputx('chr_value',trim(left(put(chr,2.))));
genegrps=catx('_',genesymbol,tissuesitedetailid);
/* where tissuesitedetailid in ("Lung","Whole_Blood"); */
/* where genesymbol="APOBEC3A"; */
run;
/* proc print data=gene_eqtls_sub(obs=10); */
/* run; */

%if %length(&min_pos)=0 %then %do;
proc sql noprint;
select min(pos) into: min_pos
from gene_eqtls_sub;
%end;

%if %length(&max_pos)=0 %then %do;
proc sql noprint;
select max(pos) into: max_pos
from gene_eqtls_sub;
%end;

%let middle_pos=%sysevalf(0.5*(&max_pos+&min_pos));

*insert the middle position into the data set gene_eqtls_sub;
%let snptag=0;
data _null_;
set gene_eqtls_sub;
if pos=&middle_pos then do;
 call symputx('snptag','1');
 call symputx('tgt_snp',snpid);
end;
run;
*Only when the middle position is not included in the dsd;
*we will add a fake snp into it;
%if "&snptag"="0" %then %do;
data gene_eqtls_sub;
set gene_eqtls_sub;
chr=&chr_value;
array nx{*} _numeric_;
if _n_=1 then do;
 output;
 snpid="rs00000";
 pos=&middle_pos;
 genesymbol=upcase("%scan(&genes,1,%str( ))");
 do i=1 to dim(nx);
  vname=vname(nx{i});
  if vname^="pos" and vname^="chr" then nx{i}=.;
 end;
 output;
end;
else do;
 output;
end;
drop vname i;
run;
%let tgt_snp=rs00000;
%end;


%long2wide4multigrpsSameTypeVars(
long_dsd=gene_eqtls_sub,
outwide_dsd=tgtgenewidedsd,
grp_vars=snpid chr pos,
subgrpvar4wideheader=genegrps,
dlm4subgrpvar=X,
ithelement4subgrpvar=1,
SameTypeVars=_numeric_
);

/* proc contents data=tgtgenewidedsd; */
/* run; */

%VarnamesInDsd(indsd=tgtgenewidedsd,Rgx=pValue,match_or_not_match=1,outdsd=pval_vars);
proc sql noprint;
select name into: pvars separated by ' '
from pval_vars;
%VarnamesInDsd(indsd=tgtgenewidedsd,Rgx=nes_,match_or_not_match=1,outdsd=nes_vars);
proc sql noprint;
select name into: nesvars separated by ' '
from nes_vars;
/* %debug_macro; */
%SNP_Local_Manhattan_With_GTF(
/*to make the genes separated better based on distance;GTF(/*As this macro use other sub-macros, it is not uncommon that some global macro
vars would be in the same name, such as macro vars chr and i, thus, to avoid of crash, chr_var is used instead of macro
var chr in this macro*/
gwas_dsd=tgtgenewidedsd,
chr_var=chr,
AssocPVars=%str(&pvars),
SNP_IDs=&tgt_snp,
dist2snp=%sysevalf(0.5*(&max_pos-&min_pos)),/*in bp; left or right size distant to each target SNP for the Manhattan plot*/
SNP_Var=snpid,
Pos_Var=pos,
gtf_dsd=&hg38_gtf_dsd,
ZscoreVars=%str(&nesvars),/*Can be beta1 beat2 or other numberic vars indicating assoc or other +/- directions*/ 
gwas_labels_in_order=%sysfunc(prxchange(s/pValue//,-1,&pvars)),
design_width=1000, 
design_height=800, 
barthickness=10, /*gene track bar thinkness*/
dotsize=8, 
dist2sep_genes=0.3,/*Distance to separate close genes into different rows in the gene track; provide negative value
to have all genes in a single row in the final gene track*/
where_cndtn_for_gwasdsd=%str() /*where condition to filter input gwas_dsd*/
);

*save this eqtl data set;
data &eqtldsdout;
set tgtgenewidedsd;
run;

**********************************************************************************;
data gene_eqtls1
(where=(snpid^="rs00000"))
;
set gene_eqtls;
genegrp=prxchange("s/APOBEC/A/i",-1,genesymbol)||":"||tissueSiteDetailId;
if logP>10 then logP=10;
where pos between &min_pos and &max_pos;
run;
proc sort data=gene_eqtls1;by genegrp;

*Draw clustergram heatmap;
*estimate the clustergram height and width by calculating total number of snpid and genegrp;
*Update the macro clustergram4longformatdsd to guess the height and width by input data set;
/* proc sql noprint; */
/* select count(snpid) into: totsnps */
/* from (select unique(snpid) from gene_eqtls1); */
/* select count(genegrp) into: totgenegrps */
/* from (select unique(genegrp) from gene_eqtls1); */
/* %let clusterheight=%sysevalf(&totgenegrps*0.8,int);/*in cm */
/* %let clusterwidth=%sysevalf(&totsnps*0.5,int);/*same in cm */
/* %put The clustergram size will be &clusterheight x &clusterwidth (cm x cm); */

*Note: when the clustergram dese not look nice;
*need to change the ratios of columnweights and rowweights for proc template;


%clustergram4longformatdsd(
dsdin=gene_eqtls1,/*The input dataset is a matrix contains rownames and other numeric columns*/
rowname_var=snpid,/*the elements of rowname_var will be used to label heatmap columns*/
colname_var=genegrp,/*These column-wide names will be used to label heatmap rowlabels*/
value_var=logP,/*numeric data for heatmap cells*/
height=,/*figure height in cm; if empty, it will use the number of rownames * 0.8 as height*/
width=,/*figure width in cm; if empty, it will use the number of colnames * 0.5 as width*/
columnweights=0.02 0.98, /*figure 2 column ratio*/
rowweights=0.15 0.95, /*figure 2 row ratio*/
cluster_type=3,        /*values are 0, 1, 2, and 3 for not clustering heatmap, 
                       clustering heatmap by column, row, and both*/
colormodel=&colormodel                      
);

*Draw a clustergram without cluster these SNPs;
*Need to sort these snpid by pos;
*This failed as the macro will sort the data set by row and column internally;
/* proc sort data=gene_eqtls1;by pos genegrp; */
/* %clustergram4longformatdsd( */
/* dsdin=gene_eqtls1,/*The input dataset is a matrix contains rownames and other numeric columns */
/* rowname_var=snpid,/*the elements of rowname_var will be used to label heatmap columns */
/* colname_var=genegrp,/*These column-wide names will be used to label heatmap rowlabels */
/* value_var=logP,/*numeric data for heatmap cells */
/* height=,/*figure height in cm; if empty, it will use the number of rownames * 0.8 as height */
/* width=,/*figure width in cm; if empty, it will use the number of colnames * 0.5 as width */
/* columnweights=0.02 0.98, /*figure 2 column ratio */
/* rowweights=0.15 0.95, /*figure 2 row ratio */
/* cluster_type=2        /*values are 0, 1, 2, and 3 for not clustering heatmap,  */
/*                        clustering heatmap by column, row, and both */
/* ); */

*Draw heatmap without clustering analysis;
*However, this macro is not good compared to the other macro heatmap4longformatdsd;
/* ods graphics on/reset=all height=600 width=1000; */
/* %longformdsd4heatmap( */
/* dsdin=gene_eqtls1, */
/* row_var=genegrp, */
/* col_var=snpid, */
/* value_var=logP, */
/* value_upperthres=10, */
/* Newvalue4upper=10, */
/* value_lowerthres=1.3, */
/* Newvalue4lower=0, */
/* cluster=0, */
/* srtbyrow=1, */
/* srtbycol=1, */
/* htmap_colwgt=0.3 0.8, */
/* htmap_rowwgt=0.3 0.8, */
/* dsdout=x); */

*Simply sort the var s for the var y;
*This will be useful for pre-sort the order of y;
*It means that we can create a ordered var for y to make customized y axis in the heatmap;
*Ensure to sort by pos only, as sorting by pos and genegrp will generate wrong order by snp pos in the heatmap;
proc sort data=gene_eqtls1;
by pos;
run;
*Get total number of eqtls for adjusting the heatmap width and height;
proc sql noprint;
select count(distinct snpid) into: totsnps
from gene_eqtls1;
select count(distinct genegrp) into: totgenegrps
from gene_eqtls1;
*Draw heatmap with automatically adjusted width and height;
title "eQTL ordered by genomic position";
%heatmap4longformatdsd(
dsdin=gene_eqtls1,
xvar=snpid,
yvar=genegrp,
colorvar=logP,
fig_height=%sysevalf(25*&totgenegrps),
fig_width=%sysevalf(15*&totsnps),
outline_thickness=1,
user_yvarfmt=,
user_xvarfmt=,
colorbar_position=right,
colorrange=blue yellow green red, 
yfont_style=normal, 
xfont_style=Italic
);

*Make scatterplots with different colors for tissues;
%let sc_width=1000;
%let sc_height=400;
ods graphics/reset=all width=&sc_width height=&sc_height;
proc sgpanel data=gene_eqtls1;
/* where tissueSiteDetailId="Whole_Blood"; */
panelby geneSymbol/onepanel columns=1 novarname uniscale=column 
headerattrs=(size=8 family=arial style=italic);
scatter x=pos y=logP/groupdisplay=cluster group=tissueSiteDetailId
markerattrs=(symbol=circlefilled size=10);
rowaxis label=" " grid  logvtype=expanded logbase=10 logstyle=logexpand;
*It is important to add thresholdmin=0 to use the exact max_pos and min_pos for the xaxis;
colaxis label=" " max=&max_pos min=&min_pos offsetmax=0.02 offsetmin=0.02 thresholdmin=0;
keylegend /position=top across=5 title="Tissues";
run;
*Note: use the same sc_width but half of sc_height;
%PlotGeneTrackWithoutScatterplot(
gtf_dsd=&hg38_gtf_dsd,
chr=&chr_value,
minst=&min_pos,
maxend=&max_pos,
dist2genes=0,
dist2st_and_end=0,
design_width=&sc_width,
design_height=%sysevalf(0.5*&sc_height),
barthickness=15,
dotsize=6,
min_dist4genes_in_same_grps=0.3,
yaxis_offset4min=0.05, /*provide 0-1 value or auto to offset the min of the yaxis*/
yaxis_offset4max=0.05, /*provide 0-1 value or auto or to offset the max of the yaxis*/
xaxis_offset4min=0.02, /*provide 0-1 value or auto  to offset the min of the xaxis*/
xaxis_offset4max=0.02 /*provide 0-1 value or auto to offset the max of the xaxis*/
);

%mend;

/*Demo:
*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';

%GTEx_eQTL_genes_scatterplot(
genes=Apobec3a Apobec3b,
hg38_gtf_dsd=FM.GTF_hg38
);

*For Apobec3A promoter and gene body;
*chr22:38,935,486-39,014,814;
%GTEx_eQTL_genes_scatterplot(
genes=Apobec3a Apobec3b,
hg38_gtf_dsd=FM.GTF_hg38,
min_pos=38935486,
max_pos=39014814
);

*/

