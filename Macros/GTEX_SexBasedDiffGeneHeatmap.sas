
%macro GTEX_SexBasedDiffGeneHeatmap(GTEx_sex_gz_file,gtf_dsd,st,end,chr,vars4sortheatmap);

/**The downloaded file with multiple files included in the subdirectory, SAS will miss the file headers for these compressed data*/
/* https://www.gtexportal.org/home/datasets */
/* %let file_url=https://storage.googleapis.com/gtex_analysis_v8/sex_biased_genes_and_sbeqtl_data/GTEx_Analysis_v8_sbgenes.tar.gz; */
/* %let wkdir=%sysfunc(getoption(work)); */
/* %let output_gz_file=%sysfunc(prxchange(s/.*\///,-1,&file_url)); */
/* %dwn_http_file(httpfile_url=&file_url,outfile=&output_gz_file,outdir=&wkdir); */

*Downloaded into local computer, uncompressed and then compressed it again using 7zip;
*Uploaded it into SAS ondemand for analysis;

*%let gzfile=/home/cheng.zhong.shan/data/signif.sbgenes.txt.gz;

*Get file header of GTEx sex based differentially expressed genes for input;
%ImportFileHeadersFromZIP(zip=&gzfile,filename_rgx=gz,obs=max,sasdsdout=x,deleteZIP=0
infile_command=%str(firstobs=1 obs=10;input;info=_infile_;));
/* proc print data=x; */
/* *THY1 gene; */
/* *where prxmatch('/^ENSG00000154096/',info); */
/* *NECTIN1 ENSG00000110400; */
/* where prxmatch('/^ENSG0000011040/',info); */
/* run; */
*Get data of GTEx sex based differentially expressed genes for input;
%ImportFileHeadersFromZIP(zip=&gzfile,filename_rgx=gz,obs=max,sasdsdout=x,deleteZIP=0,
infile_command=%str(
firstobs=2 obs=max delimiter='09'x truncover;
length gene $30. tissue $50.;
input gene $ tissue effsize effsize_se lfsr;
)
);

/* *Get file header of GTEx sex based eQTLs; */
/* %let sbeQTL=/home/cheng.zhong.shan/data/GTEx_Analysis_v8_sbeQTLs.txt.gz; */
/* %ImportFileHeadersFromZIP(zip=&sbeQTL,filename_rgx=gz,obs=max,sasdsdout=x,deleteZIP=0 */
/* infile_command=%str(lrecl=1000 firstobs=1 obs=10;input;info=_infile_;)); */
/* proc print;run; */
/* proc print data=x; */
/* *THY1 gene; */
/* *where prxmatch('/^ENSG00000154096/',info); */
/* *NECTIN1 ENSG00000110400; */
/* where prxmatch('/^ENSG0000011040/',info); */
/* run; */
/* *Get data of GTEx sex based eQTLs; */
/* %ImportFileHeadersFromZIP(zip=&sbeQTL,filename_rgx=gz,obs=max,sasdsdout=eQTLx,deleteZIP=0, */
/* infile_command=%str( */
/* firstobs=2 obs=100 delimiter='09'x truncover; */
/* length ensembl_gene_id hugo_gene_id gene_type variant_id rs_id Tissue $30.; */
/* input ensembl_gene_id $ hugo_gene_id $ gene_type $ variant_id $ rs_id $ Tissue $  */
/* maf pval_nominal_sb slope_sb slope_se_sb numtested pvalscorrected qval pval_nominal_f  */
/* slope_f slope_se_f pval_nominal_m slope_m slope_se_m pval_nominal slope slope_se; */
/* ) */
/* ); */
/*  */
/* *It is not expected that these COVID19 sex differential snps would be sex specific eQTLs; */
/* data eqtl_top; */
/* set eQTLx; */
/* where rs_id in ("rs8116534","rs472481","rs555336963","rs148143613","rs2924725","rs5927942","rs2443615","rs1965385","rs1134004","rs35239301","rs140657166","rs200808810"); */
/* run; */


data x;
set x;
gene=scan(gene,1,'.');
run;

/* *Get all genes around these top snps; */
/* libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp'; */
/* proc print data=FM.gtf_hg19(obs=10); */
/* run; */
/* %let dist=1000000; */
/* data snps(keep=rsid chr st end); */
/* set FM.f_vs_m_mixedpop; */
/* st=pos-&dist; */
/* end=pos+&dist; */
/* where rsid in ("rs16831827"); */
/* run; */

/* *Get genes included in the regions harboring snps; */
/* proc print data=FM.gtf_hg19(obs=10);run; */

proc sql;
create table target_genes as 
select b.genesymbol,b.ensembl
from 
     &gtf_dsd (where=(type="gene" and protein_coding>0)) as b
where b.chr=&chr and (
      (b.st between &st and &end) or (b.end between &st and &end)
      );
proc sort data=target_genes nodupkeys;by _all_;run;
proc print; var rsid genesymbol;run;

*Get sex based differential genes statistics for the above genes;
proc sql;
create table target_genes_new as
select a.*,b.*
from target_genes as a
left join
x as b 
on scan(a.ensembl,1,'.')=b.gene;

*Calculate -log10P for sex based differential gene expression;     
data target_genes_new(where=(tissue^=""));
set target_genes_new;
if lfsr=. then log10P=0;
else log10P=-log10(lfsr);
/* genes=trim(left(rsid))||"   "||genesymbol; */
genes=genesymbol;
run;
proc sql;
select count(unique(genesymbol))
from target_genes_new;

*Make heatmap using sgpanel by rsid;
*This does not work, as it only make frequency heatmap;
/* ods graphics on/height=200 width=1200; */
/* proc sgplot data=target_genes_new; */
/* heatmap x=genesymbol y=log10P; */
/* xaxis grid; */
/* yaxis grid; */
/* by rsid; */
/* run; */

/* ods graphics / width=1200 height=1000px; */
/* proc sgplot data=x(where=(cohort="Laval")); */
/* proc sgplot data=target_genes_new; */
/* outline and its attrs are important for making white grid */
/* heatmapparm x=tissue y=genes colorresponse=log10P/outline */
/*             outlineattrs=(color=white thickness=2 pattern=solid) */
/*             colormodel=(blue green red) */
/*             ; */
/* customize gene font and font size             */
/* yaxis fitpolicy=split valueattrs=(Style=Italic size=8);   */
/* adjust colorbar postion        */
/* gradlegend/integer position=bottom; */
/* run; */
/* ods listing close; */
/* ods listing; */

/*
%getdsdvarsfmt(dsdin=target_genes_new,fmtdsdout=fmtinfo);
proc print;run;
options mprint mlogic symbolgen;
%mkfmt4grpsindsd(
targetdsd=target_genes_new,
grpvarintarget=genesymbol,
name4newfmtvar=srt_gene_names,
fmtdsd=target_genes_new,
grpvarinfmtdsd=genesymbol,
byvarinfmtdsd=rsid,
finaloutdsd=dsd4heatmap
);
*/

*No need to use mkfmt4grpsindsd, as sorting the dataset; 
*by rsid and tissue will enable the final heatmap produced as expected;
proc sort data=target_genes_new;by &vars4sortheatmap;run;
%heatmap4longformatdsd(
dsdin=target_genes_new,
xvar=tissue,
yvar=genes,
colorvar=log10P,
fig_height=800,
fig_width=1200,
outline_thickness=4
);

%heatmap4longformatdsd(
dsdin=target_genes_new,
xvar=tissue,
yvar=genes,
colorvar=log10P,
fig_height=800,
fig_width=1200,
outline_thickness=4
);

/* data o; */
/* length rsid $15.; */
/* input rsid $15.; */
/* ord=_n_; */
/* cards; */
/* rs16831827 */
/* ; */
/* run; */
/* proc sql; */
/* create table taget_genes_new as */
/* select a.*,b.ord */
/* from target_genes_new as a */
/* left join */
/* o as b */
/* on a.rsid=b.rsid */
/* order by b.ord,a.tissue; */
/* proc sql; */
/* select unique(genesymbol) */
/* from target_genes_new; */
proc sort data=target_genes_new;by &vars4sortheatmap;run;

%heatmap4longformatdsd(
dsdin=target_genes_new,
xvar=genes,
yvar=tissue,
colorvar=log10P,
fig_height=1000,
fig_width=1200,
outline_thickness=4
);
 
/* *Make frequency heatmap for tissues; */
/* ods graphics on/height=400 width=1200; */
/* proc sgplot data=target_genes_new; */
/* heatmap x=tissue y=log10P/outline */
/*         outlineattrs=(color=grep thickness=2 pattern=solid) */
/*         colormodel=(blue green red);   */
/* gradlegend/integer position=bottom;         */
/* run; */
/* ods listing close; */
/* ods listing; */

%heatmap4longformatdsd(
dsdin=target_genes_new,
xvar=tissue,
yvar=log10P,
colorvar=,
fig_height=1000,
fig_width=1200,
outline_thickness=5
);
 
%mend;

/*Demo:

*options mprint mlogic symbolgen;
%let macrodir=/home/cheng.zhong.shan/Macros;
%include "&macrodir/importallmacros_ue.sas";
%importallmacros_ue;

libname FM '/home/cheng.zhong.shan/my_shared_file_links/cheng.zhong.shan/F_vs_M_Covid19_Hosp';
proc print data=FM.gtf_hg19(obs=10);

%GTEX_SexBasedDiffGeneHeatmap(
GTEx_sex_gz_file=/home/cheng.zhong.shan/data/signif.sbgenes.txt.gz,
gtf_dsd=FM.gtf_hg19,
st=300000,
end=1000000,
chr=1,
vars4sortheatmap=st
);


*/


